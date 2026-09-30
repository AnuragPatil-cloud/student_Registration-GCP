#!/bin/bash
# Bootstrap for the Jenkins VM (Ubuntu 24.04 on Compute Engine).
# Installs: Docker, Jenkins, Java 21 + Maven, Node.js 22, gcloud CLI, Ops Agent, and a SonarQube container.
#
# Compute Engine runs the startup script on EVERY boot, so the real work is guarded by a marker file.
# Progress: sudo journalctl -u google-startup-scripts.service   (or the VM's serial console output)
set -euo pipefail

MARKER=/var/lib/student-registration-jenkins.bootstrapped
if [ -f "${MARKER}" ]; then
  echo "Jenkins VM already bootstrapped - nothing to do."
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg unzip git fontconfig openjdk-21-jdk-headless maven docker.io apt-transport-https

# SonarQube kernel settings
echo "vm.max_map_count=524288" > /etc/sysctl.d/99-sonarqube.conf
echo "fs.file-max=131072" >> /etc/sysctl.d/99-sonarqube.conf
sysctl --system >/dev/null

systemctl enable --now docker

# Node.js 22 (the pipeline's "Frontend Build" stage runs npm ci / npm run build on this VM)
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Google Cloud CLI: authenticates docker to Artifact Registry using this VM's service account
install -m 0755 -d /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
apt-get install -y google-cloud-cli

# Ops Agent: memory / disk / process metrics and logs in Cloud Monitoring and Cloud Logging
curl -fsSL -o /tmp/add-google-cloud-ops-agent-repo.sh https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash /tmp/add-google-cloud-ops-agent-repo.sh --also-install

# Jenkins
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key -o /etc/apt/keyrings/jenkins.asc
echo "deb [signed-by=/etc/apt/keyrings/jenkins.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y jenkins
systemctl enable --now jenkins
usermod -aG docker jenkins
systemctl restart jenkins

# SonarQube (Community)
docker volume create sonarqube_data || true
docker volume create sonarqube_extensions || true
docker volume create sonarqube_logs || true

docker rm -f sonarqube 2>/dev/null || true
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  -v sonarqube_logs:/opt/sonarqube/logs \
  sonarqube:community

touch "${MARKER}"
echo "Jenkins bootstrap finished. Initial admin password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
