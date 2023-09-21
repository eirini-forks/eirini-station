#!/bin/bash
set -euo pipefail

readonly USAGE="Usage: provision.sh [-l | -c <command_name>]"

main() {
  if [[ $EUID -ne 0 ]]; then
    echo "Script must be run as root."
    exit 1
  fi

  while getopts ":lch" opt; do
    case ${opt} in
      l)
        declare -F | awk '{ print $3 }' | grep -v main
        exit 0
        ;;
      c)
        shift $((OPTIND - 1))
        for command in "$@"; do
          $command
        done
        exit $?
        ;;
      h)
        echo "$USAGE"
        exit 0
        ;;
      \?)
        echo "Invalid option: $OPTARG" 1>&2
        echo "$USAGE"
        exit 1
        ;;
    esac
  done
  shift $((OPTIND - 1))
  echo ">>> Installing everything..."
  add_swap
  add_sshd_config
  setup_locale
  setup_inotify_limit
  setup_pam
  install_packages
  install_aws_cli
  install_kubectl
  install_neovim
  install_nodejs
  install_language_servers
  install_gcloud_cli
  install_golang
  install_cf_tools
  install_github_cli
  install_misc_tools
  install_helm3
  install_hashicorp_tools
}

add_swap() {
  local swapsize=4096

  if ! grep -q "swapfile" /etc/fstab; then
    echo 'swapfile not found. Adding swapfile.'
    fallocate -l ${swapsize}M /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap defaults 0 0' >>/etc/fstab
  else
    echo 'swapfile found. No changes made.'
  fi
}

add_sshd_config() {
  echo "StreamLocalBindUnlink yes" >/etc/ssh/sshd_config.d/streamlocalbindunlink.conf
  systemctl restart ssh.service
}

setup_locale() {
  echo ">>> Setting up the en_US locale"
  apt-get -y install locales
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.UTF-8
}

setup_inotify_limit() {
  echo ">>> Setting up inotify limit"

  echo "fs.inotify.max_user_watches = 524288" >/etc/sysctl.d/50-inotify-limit.conf
  echo "fs.inotify.max_user_instances = 512" >>/etc/sysctl.d/50-inotify-limit.conf

  service procps force-reload
}

setup_pam() {
  echo ">>> pre-configuring PAM"
  pam-auth-update --force --enable capability pwquality systemd unix
}

install_packages() {
  echo ">>> Installing the APT packages"
  apt-get update
  apt-get -y install \
    apt-transport-https \
    autoconf \
    automake \
    bison \
    build-essential \
    ca-certificates \
    cmake \
    cowsay \
    curl \
    direnv \
    exuberant-ctags \
    fd-find \
    fortune \
    libfuse2 \
    g++ \
    git \
    gnupg-agent \
    iputils-ping \
    jq \
    lastpass-cli \
    libbtrfs-dev \
    libdb-dev \
    libdevmapper-dev \
    libevent-dev \
    libffi-dev \
    libgdbm-dev \
    libgdbm6 \
    libmysqlclient-dev \
    libncurses5-dev \
    libpq-dev \
    libreadline-dev \
    libreadline6-dev \
    libssl-dev \
    libtool \
    libtool-bin \
    libyaml-dev \
    lolcat \
    net-tools \
    netcat-openbsd \
    ntp \
    openconnect \
    openssh-server \
    pass \
    pkg-config \
    postgresql \
    postgresql-contrib \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ripgrep \
    ruby-dev \
    rubygems \
    shellcheck \
    socat \
    software-properties-common \
    sshfs \
    stow \
    tig \
    tmux \
    trash-cli \
    unzip \
    wget \
    xsel \
    zlib1g-dev \
    zsh 
}

install_kubectl() {
  echo ">>> Installing kubectl"
  #snap remove google-cloud-sdk
  #snap install kubectl --classic
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  RESULT=$(echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check)
  if [[ ! $RESULT == "kubectl: OK" ]]
   then echo "failure installing kubectl"
   exit 0
  fi
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}

install_neovim() {
  echo ">>> Installing Neovim"
  rm -f /usr/bin/nvim
  curl -sSfLo nvim https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  mv nvim /usr/local/bin/nvim
  chmod a+x /usr/local/bin/nvim
}

install_golang() {
  echo ">>> Installing Golang"
  rm -rf /usr/local/go
  add-apt-repository -y ppa:longsleep/golang-backports
  apt-get -y install golang-go
}

install_nodejs() {
  echo ">>> Installing NodeJS"
  rm -f /etc/apt/trusted.gpg.d/nodesource.gpg
  rm -f /etc/apt/sources.list.d/nodesource.list
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/nodesource.gpg
  NODE_MAJOR=16
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
  chmod 644 /etc/apt/trusted.gpg.d/nodesource.gpg
  apt-get update
  apt-get -y install nodejs
}

install_gcloud_cli() {
  echo ">>> Installing the Google Cloud CLI"
  curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-445.0.0-linux-x86_64.tar.gz
  tar -xf google-cloud-cli-445.0.0-linux-x86_64.tar.gz
  ./google-cloud-sdk/install.sh -q --rc-path ~/.bashrc
  source ~/.bashrc
}

install_cf_tools() {
  echo ">>> Installing the Cloud Foundry CLI"
  rm -f /etc/apt/trusted.gpg.d/cloudfoundry-cli.gpg
  rm -f /etc/apt/sources.list.d/cloudfoundry-cli.list
  wget -qO- https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/cloudfoundry-cli.gpg
  echo "deb https://packages.cloudfoundry.org/debian stable main" | tee /etc/apt/sources.list.d/cloudfoundry-cli.list
  chmod 644 /etc/apt/trusted.gpg.d/cloudfoundry-cli.gpg
  apt-get update
  apt-get -y install cf8-cli

  url="$(curl -sSfL https://api.github.com/repos/cloudfoundry/bosh-cli/releases/latest | jq -r '.assets[]|select(.name|match("linux-amd64")).browser_download_url')"
  curl -sSfLo /usr/bin/bosh "$url" && chmod +x /usr/bin/bosh
}

install_aws_cli() {
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install --update
  rm -rf aws awscliv2.zip
}

install_hashicorp_tools() {
  echo ">>> Installing Vault and Terraform"
  rm -f /etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg
  rm -f /etc/apt/sources.list.d/hashicorp.list
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  chmod 644 /etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg
  apt-get update
  apt-get install -y vault terraform
}

install_misc_tools() {
  echo ">>> Installing git-duet"
  curl -sSfL "https://github.com/git-duet/git-duet/releases/latest/download/linux_amd64.tar.gz" | tar xvz -C /usr/bin

  echo ">>> Installing yq"
  curl -sSfL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" >/usr/local/bin/yq && chmod a+x /usr/local/bin/yq

  echo ">>> Installing the carvel tools"
  curl -sL https://carvel.dev/install.sh | bash
}

install_language_servers() {
  echo ">>> Installing language servers"
  #snap install bash-language-server --classic
  #snap install typescript-language-server
  apt-get install -y node-read-package-json
  npm install -g typescript-language-server typescript
  npm install -g bash-language-server
}

install_github_cli() {
  echo ">>> Installing Github CLI"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null 
  apt-get update
  apt-get install -y gh
}

install_helm3() {
  echo ">>> Installing Helm 3"
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/helm.gpg > /dev/null
  apt-get install apt-transport-https --yes
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
  chmod 644 /etc/apt/trusted.gpg.d/helm.gpg
  apt-get update
  apt-get install -y helm
}

main "$@"
