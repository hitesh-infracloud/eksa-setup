echo
echo "##################################################"
echo -e "[+] Updating package manager"
apt-get update

echo
echo "##################################################"
echo -e "[+] Installing docker"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
apt-get update
apt-get install --no-install-recommends containerd.io docker-ce docker-ce-cli docker-compose-plugin
gpasswd -a vagrant docker

echo
echo "##################################################"
echo -e "[+] Installing kubectl cli"
curl -LO https://dl.k8s.io/v1.25.2/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

echo
echo "##################################################"
echo -e "[+] install latest eksctl cli tool"
curl "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    --silent --location \
    | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/

echo
echo "##################################################"
echo -e "[+] install yq tool"
snap install yq

echo
echo "##################################################"
echo -e "[+] install later eksctl-anywhere plugin"
RELEASE_VERSION=$(curl https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml --silent --location | yq ".spec.latestVersion")
EKS_ANYWHERE_TARBALL_URL=$(curl https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml --silent --location | yq ".spec.releases[] | select(.version==\"$RELEASE_VERSION\").eksABinary.$(uname -s | tr A-Z a-z).uri")
curl $EKS_ANYWHERE_TARBALL_URL \
    --silent --location \
    | tar xz ./eksctl-anywhere
sudo mv ./eksctl-anywhere /usr/local/bin/