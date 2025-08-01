#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source $SCRIPT_DIR/provision-env.sh

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
  fix_umask
  add_swap
  add_sshd_config
  setup_locale
  setup_inotify_limit
  install_packages
  install_aws_cli
  install_snap
  install_snaps
  install_kubectl
  install_neovim
  install_nodejs
  install_language_servers
  install_golang
  install_cf_tools
  install_github_cli
  install_misc_tools
  install_helm3
  install_hashicorp_tools
}

fix_umask() {
  # set umask to default value for ubuntu (it is set to the restrictive 077 value by SAP)
  # this value will be in effect during installation
  umask 022
  # make sure the restrictive umask is deleted from config, so that it is back to default value
  # on next login
  sed -i '/^UMASK/d' /etc/login.defs
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
    libfuse2 \
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
    luarocks \
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
    socat \
    software-properties-common \
    sshfs \
    stow \
    tig \
    trash-cli \
    unzip \
    wget \
    xsel \
    zlib1g-dev \
    zsh
}
install_snap() {
  snap_version="$(apt list --all-versions snapd | tail -n +2 | head -1 | awk '{print $2}')"
  apt install -y snapd="$snap_version"
}

install_snaps() {
  echo ">>> Installing the Snap packages"
  rm -f /usr/bin/nvim
  snap install lolcat
  snap install shellcheck --edge

  snap install tmux --classic
  rm -rf /usr/bin/tmux
  ln -s /snap/tmux/current/usr/local/bin/tmux /usr/bin
}

install_kubectl() {
  echo ">>> Installing kubectl"
  snap remove google-cloud-sdk
  snap install kubectl --classic
}

install_neovim() {
  echo ">>> Installing Neovim"
  curl -sSfLo nvim https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
  mv nvim /usr/local/bin/nvim
  chmod a+x /usr/local/bin/nvim
}

install_golang() {
  echo ">>> Installing Golang"
  rm -rf /usr/local/go

  GO_VERSION=1.24.1
  wget "https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz"
  tar -C /usr/local -xzf "go$GO_VERSION.linux-amd64.tar.gz"
  rm "go$GO_VERSION.linux-amd64.tar.gz"
}

install_nodejs() {
  echo ">>> Installing NodeJS"
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --batch --yes -o /etc/apt/trusted.gpg.d/nodesource.gpg
  NODE_MAJOR=22
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
  chmod 644 /etc/apt/trusted.gpg.d/nodesource.gpg
  apt-get update
  apt-get -y install nodejs
}

install_cf_tools() {
  echo ">>> Installing the Cloud Foundry CLI"
  wget -qO- https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | gpg --dearmor --batch --yes -o /etc/apt/trusted.gpg.d/cloudfoundry-cli.gpg
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
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor --batch --yes -o /etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
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

  echo ">>> Installing buildkit-cli-for-kubectl"
  curl -sSfL "https://github.com/vmware-archive/buildkit-cli-for-kubectl/releases/download/v0.1.6/linux-v0.1.6.tgz" | tar xvz -C /usr/bin
}

install_language_servers() {
  echo ">>> Installing language servers"
  snap install bash-language-server --classic
  snap install typescript-language-server
}

install_github_cli() {
  echo ">>> Installing Github CLI"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg &&
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg &&
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list
  apt-get update
  apt-get install -y gh
}

install_helm3() {
  echo ">>> Installing Helm 3"
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor --batch --yes -o /etc/apt/trusted.gpg.d/helm.gpg
  apt-get install apt-transport-https --yes
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
  chmod 644 /etc/apt/trusted.gpg.d/helm.gpg
  apt-get update
  apt-get install -y helm
}

main "$@"
