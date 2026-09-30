pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 60, unit: 'MINUTES')
    }

    environment {
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"

        // Google Cloud. The project ID is read from the VM's metadata server in the "Verify GCP" stage.
        GCP_REGION = 'asia-south1'

        // Artifact Registry repository created by Terraform (one repo, two images)
        AR_REPO = 'student-registration'

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tooling') {
            steps {
                sh '''
                    java -version
                    javac -version
                    mvn -version
                    node --version
                    npm --version
                    docker --version
                    gcloud --version | head -1
                '''
            }
        }

        stage('Verify GCP') {
            steps {
                script {
                    env.GCP_PROJECT_ID = sh(
                        returnStdout: true,
                        script: "curl -fsS -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/project/project-id"
                    ).trim()

                    // Full image paths, reused by the stages below
                    env.AR_PATH        = "${env.GCP_REGION}-docker.pkg.dev/${env.GCP_PROJECT_ID}/${env.AR_REPO}"
                    env.BACKEND_IMAGE  = "${env.AR_PATH}/backend"
                    env.FRONTEND_IMAGE = "${env.AR_PATH}/frontend"
                }

                sh '''
                    set -e
                    echo "GCP project : ${GCP_PROJECT_ID}"
                    echo "GCP region  : ${GCP_REGION}"
                    echo "Backend img : ${BACKEND_IMAGE}:${IMAGE_TAG}"
                    echo "Frontend img: ${FRONTEND_IMAGE}:${IMAGE_TAG}"

                    gcloud auth list

                    gcloud artifacts repositories describe "${AR_REPO}" \
                        --project "${GCP_PROJECT_ID}" \
                        --location "${GCP_REGION}"
                '''
            }
        }

        stage('Backend Test') {
            steps {
                dir('backend') {
                    sh 'mvn -B clean test'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir('backend') {
                    // "SonarQube" = server name configured in Manage Jenkins > System (it holds the token)
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            mvn -B sonar:sonar \
                                -Dsonar.projectKey=student-registration-backend
                        '''
                    }
                }
            }
        }

        stage('Frontend Build') {
            steps {
                dir('frontend') {
                    sh '''
                        npm ci
                        npm run build
                    '''
                }
            }
        }

        stage('Build Images') {
            steps {
                sh '''
                    set -e

                    docker build \
                        -t "${BACKEND_IMAGE}:${IMAGE_TAG}" \
                        ./backend

                    docker build \
                        --build-arg VITE_API_URL=/api \
                        -t "${FRONTEND_IMAGE}:${IMAGE_TAG}" \
                        ./frontend
                '''
            }
        }

        stage('Push to Artifact Registry') {
            steps {
                sh '''
                    set -e

                    # Authenticates as the Jenkins VM's service account - no key file, no stored credential.
                    gcloud auth print-access-token |
                    docker login \
                        --username oauth2accesstoken \
                        --password-stdin "https://${GCP_REGION}-docker.pkg.dev"

                    docker push "${BACKEND_IMAGE}:${IMAGE_TAG}"
                    docker push "${FRONTEND_IMAGE}:${IMAGE_TAG}"
                '''
            }
        }

        stage('Update Helm Values') {
            steps {
                sh '''
                    set -e
                    bash ./scripts/update-helm-values.sh \
                        "${BACKEND_IMAGE}" \
                        "${FRONTEND_IMAGE}" \
                        "${IMAGE_TAG}"
                '''
            }
        }

        stage('Commit Helm Change') {
            steps {
                sh '''
                    git config user.name "Jenkins CI"
                    git config user.email "jenkins@localhost"

                    git add helm/student-registration/values.yaml

                    git commit -m "Update application images to ${IMAGE_TAG}" \
                        || echo "No changes to commit"
                '''
            }
        }

        stage('Push Helm Change') {
            steps {
                withCredentials([
                    gitUsernamePassword(
                        credentialsId: 'github-credentials',
                        gitToolName: 'Default'
                    )
                ]) {
                    sh 'git push origin HEAD:main'
                }
            }
        }
    }

    post {
        always {
            sh '''
                docker logout "https://${GCP_REGION}-docker.pkg.dev" || true
                docker rmi "${BACKEND_IMAGE}:${IMAGE_TAG}" "${FRONTEND_IMAGE}:${IMAGE_TAG}" || true
                docker image prune -f || true
            '''
        }
        success {
            echo "Build ${BUILD_NUMBER} pushed. Argo CD will sync helm/student-registration into GKE."
        }
        failure {
            echo "Build ${BUILD_NUMBER} failed - check the failing stage's console output."
        }
    }
}
