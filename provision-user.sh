#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source $SCRIPT_DIR/provision-env.sh

readonly USAGE="Usage: provision.sh [-l | -c <command_name>]"

main() {
  while getopts ":lch" opt; do
    case ${opt} in
      l)
        declare -F | awk '{ print $3 }' | grep -vE "(main|git_clone)"
        exit 0
        ;;
      c)
        shift $((OPTIND - 1))
        for command in "$@"; do
          $command
        done
        exit 0
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
  mkdir_home_user_bin
  setup_non_root_npm_install_global
  install_gotools
  install_docker
  install_ohmyzsh
  install_nvim_extensions
  install_cred_alert
  configure_dotfiles
  clone_git_repos
  install_misc_tools
  install_pure_zsh_theme
  install_tmux_plugin_manager
  install_zsh_autosuggestions
  install_openstack_clients
  install_gcloud_cli
  switch_to_zsh
}

mkdir_home_user_bin() {
  mkdir -p "$HOME/bin"
}

setup_non_root_npm_install_global() {
  mkdir -p "${HOME}/.npm-packages"
  npm config set prefix "${HOME}/.npm-packages"
}

install_cred_alert() {
  os_name=$(uname | awk '{print tolower($1)}')
  url="$(curl -sSfL https://api.github.com/repos/pivotal-cf/cred-alert/releases/latest | jq -r '.assets[]|select(.name|match("linux")).browser_download_url')"
  curl -sSfLo cred-alert-cli "$url"
  chmod 755 cred-alert-cli
  mv cred-alert-cli "$HOME/bin/"
}

install_docker() {
  echo ">>> Installing Docker"
  if command -v docker; then
    sudo apt upgrade docker-ce docker-ce-cli docker-ce-rootless-extras -y
  else
    curl -fsSL get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
  fi
}

install_gotools() {
  echo ">>> Installing gopls"
  go install golang.org/x/tools/gopls@latest

  echo ">>> Installing setup-envtest"
  go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
}

install_ohmyzsh() {
  echo ">>> Installing Oh My Zsh"
  [ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  # Delete default .zshrc to avoid stow conflicts
  rm -f "$HOME/.zshrc"
}

install_tmux_plugin_manager() {
  echo ">>> Installing TPM"
  git_clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
}

install_zsh_autosuggestions() {
  echo ">>> Installing zsh-autosuggestions"
  git_clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
}

install_nvim_extensions() {
  echo ">>> Installing the NeoVim extensions"
  npm install -g neovim
  sudo apt -y install python3-pip
  sudo apt -y install python3-neovim
  gem install neovim --user-install
}

clone_git_repos() {
  echo ">>> Cloning our Git repositories"

  mkdir -p "$HOME/workspace"
  pushd "$HOME/workspace"
  {
    git_clone "https://github.com/cloudfoundry/korifi.git"
    git_clone "https://github.com/cloudfoundry/korifi-ci.git"
    #git_clone "https://github.com/cloudfoundry/cf-k8s-secrets.git"
    git_clone "https://github.com/eirini-forks/eirini-station.git"
  }

  popd
}

git_clone() {
  local url path name branch
  url=$1
  path=${2:-""}
  branch=${3:-""}

  if [ -z "$path" ]; then
    name=${url%%.git}
    name=${name##*/}
    path="$HOME/workspace/$name"
  fi

  if [ -d "$path" ]; then
    echo "Repository $path already exists. Skipping git clone..."
    return
  fi

  git clone "$url" "$path"

  if [ -f "$path/.gitmodules" ]; then
    git -C "$path" submodule update --init --recursive
  fi

  if [ -n "$branch" ]; then
    git -C "$path" switch "$branch"
  fi
}

configure_dotfiles() {
  echo ">>> Installing eirini-home"
  # backing up any previous existing ssh-key
  if [ -f $HOME/.ssh/authorized_keys ]; then
    KEYS="$(cat $HOME/.ssh/authorized_keys)"
  fi

  ssh-keyscan -t rsa github.com >>"$HOME/.ssh/known_hosts"

  git_clone "https://github.com/pivotal-cf/git-hooks-core.git"
  #git_clone "https://github.com/cloudfoundry/eirini-private-config.git"
  git_clone "https://github.com/eirini-forks/eirini-home.git"

  pushd "$HOME/workspace/eirini-home"
  {
    git checkout master
    git pull -r
    ./install.sh

    export GIT_DUET_CO_AUTHORED_BY=1
    export GIT_DUET_GLOBAL=true
    git duet ae ae # initialise git-duet
    git init       # install git-duet hooks on eirini-home
  }
  popd
  # restoring previously backed up ssh-keys
  if [ "$KEYS" ]; then
    echo "$KEYS" >>$HOME/.ssh/authorized_keys
  fi
}

install_misc_tools() {
  echo ">>> Installing concourse-flake-hunter"
  go install github.com/eirini-forks/concourse-flake-hunter@latest

  echo ">>> Installing fly"
  curl -sL "https://ci.korifi.cf-app.com/api/v1/cli?arch=amd64&platform=linux" -o "$HOME/bin/fly"
  chmod +x "$HOME/bin/fly"

  echo ">>> Installing k9s"
  curl -LsSf https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | tar xvzf - -C "$HOME/bin" k9s

  echo ">>> Installing kind"
  curl -LsSf https://github.com/kubernetes-sigs/kind/releases/latest/download/kind-linux-amd64 -o "$HOME/bin/kind"
  chmod +x "$HOME/bin/kind"

  echo ">>> Installing shfmt"
  go install mvdan.cc/sh/v3/cmd/shfmt@latest
}

install_pure_zsh_theme() {
  echo ">>> Installing the pure prompt"
  mkdir -p "$HOME/.zsh"
  git_clone "https://github.com/sindresorhus/pure.git" "$HOME/.zsh/pure"
  pushd "$HOME/.zsh/pure"
  {
    # pure have switched from `master` to `main` for their main branch
    # TODO remove this once everyone has been migrated
    if git show-ref --quiet refs/heads/master; then
      git branch -m master main
      git branch --set-upstream-to=origin/main
    fi
    git pull -r
  }
  popd
}

install_openstack_clients() {
  echo ">>> Installing openstack clients"
  sudo apt -y install python3-openstackclient
  sudo apt -y install python3-barbicanclient
}

install_gcloud_cli() {
  echo ">>> Installing gcloud cli"
  rm -rf $HOME/google-cloud-sdk
  curl https://sdk.cloud.google.com >/tmp/install-gcloud-cli.sh
  bash /tmp/install-gcloud-cli.sh --disable-prompts
  $HOME/google-cloud-sdk/bin/gcloud components install --quiet gke-gcloud-auth-plugin
}

switch_to_zsh() {
  echo ">>> Setting Zsh as the default shell"
  sudo chsh -s /bin/zsh "$(whoami)"
}

main "$@"
