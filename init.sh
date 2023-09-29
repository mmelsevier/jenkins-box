#!/bin/bash -xe

# Gain root access
sudo -i

### Update packages
apt-get update; apt-get full-upgrade -y; apt-get autoclean -y;

### Install Docker so that we can run Jenkins agents (jobs) inside containers.
### This enables us to reduce our reliance on Jenkins plugins.

# Uninstall all conflicting packages
for pkg in docker.io docker-doc docker-compose containerd runc; do sudo apt-get remove $pkg; done

# Install packages to allow `apt` to use repo over HTTPS
apt-get install ca-certificates curl gnupg -y

# Add Docker's GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine, containerd and Docker Compose
apt-get update -y
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

### Install AWS and Terraform CLI tools so that we can deploy infrastructure from the Jenkins server.

# Install AWS CLI v2

# Get the CLI download URL, which differs depending on the architecture of the instance
arch=$(uname -m)

AWS_CLI_URL=""

if [ "$arch" == "x86_64" ]; then
    AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
elif [ "$arch" == "aarch64" ]; then
    AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
else
    echo "Unsupported architecture: $arch"
    exit 1
fi

# Download and install the CLI
curl $AWS_CLI_URL -o "awscliv2.zip"
apt-get install unzip -y
unzip awscliv2.zip
./aws/install

# Install Terraform CLI

# Install HashiCorp GPG key and verify its fingerprint
apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

# Add Hashicorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list

# Download package information from HashiCorp
apt update

# Install Terraform
apt-get install terraform -y

### Mount Elastic File System resource so that it can store the Jenkins state. This allows us to easily
### replace the EC2 instance for various reasons, such as redeploying with new initialisation
### scripts.

# Install Network File System (NFS) utilities to mount remote directories on the instance
apt install nfs-common -y

# Mount volume
JENKINS_DIR=/var/lib/jenkins
mkdir -p $JENKINS_DIR
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${EFS_DNS}:/ $JENKINS_DIR

# Make mount permanent
echo ${EFS_DNS}:/ $JENKINS_DIR nfs defaults 0 0 | cat >> /etc/fstab

### Install Jenkins

# Install Java
apt-get install openjdk-17-jdk openjdk-17-jre -y

# Import key file from Jenkins-CI to enable installation from package
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repo
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
apt-get update -y
apt-get install jenkins -y

# Enable Jenkins to start at boot
systemctl enable jenkins

# Add Jenkins user to the docker group so it can run Docker
usermod -a -G docker jenkins

# Restart Jenkins
systemctl restart jenkins