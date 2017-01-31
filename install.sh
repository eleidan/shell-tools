#!/bin/bash

OK="OK"
DONE="DONE"
DOWNLOADS_PATH=$HOME/install-tmp

function prepare {
  mkdir -p $DOWNLOADS_PATH
  mkdir -p $HOME/forge
}

function exists {
  if [[ -f $1 ]]
  then
    echo $OK
    return 1
  else
    return 0
  fi
}

function check_installed {
  which $1 > /dev/null
  if [[ "$?" -eq "0" ]]
  then
    echo $OK
    return 1
  else
    return 0
  fi
}

function read_lsb_release {
  source /etc/lsb-release
}

function clean_up {
  echo "CLEAN UP" \
    && rm -rf $DOWNLOADS_PATH \
    && echo $DONE
}


################################################################################
# Check if command is issued with proper privileges
if [[ "$(id -u)" -ne "0" ]]; then
  echo "This script requires root privileges!"
fi


prepare

################################################################################
# BASH
BASH_FILE=$HOME/.bashrc

function check_customizations {
  grep "bash_customizations" $BASH_FILE > /dev/null
  if [[ "$?" -eq "0" ]]; then
    echo $OK
    return 1
  fi
}

echo -n "Bash : " \
  && check_customizations \
  && echo -e "\nif [ -f ~/.bash_customizations ]; then" >> $BASH_FILE \
  && echo "  . ~/.bash_customizations" >> $BASH_FILE \
  && echo "fi" >> $BASH_FILE \
  && echo $DONE


################################################################################
# SSH
echo -n "SSH : " \
  && exists $HOME/.ssh/id_rsa \
  && ssh-keygen -t rsa \
  && echo $DONE



################################################################################
# GIT
function set_aliases {
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.ci commit
  git config --global alias.st status
  git config --global alias.last 'log -1 HEAD'
}

function initial_setup {
  git config --global user.name "John Doe"
  git config --global user.email johndoe@example.com
  git config --global --edit
}

echo -n "Git : " \
  && set_aliases \
  && initial_setup \
  && echo $DONE



################################################################################
# ATOM
# NOTE: depends on Git
ATOM_PKG=$DOWNLOADS_PATH/atom.deb
echo -n "Atom : " \
  && check_installed "atom" \
  && wget -c -O $ATOM_PKG https://atom.io/download/deb \
  && sudo dpkg -i $ATOM_PKG \
  && rm $ATOM_PKG



################################################################################
# DOCKER
function prerequisites {
  read_lsb_release
  case $DISTRIB_RELEASE in
    "16.04" )
      echo "Installing prerequisites for Ubuntu 16.04:" \
        && echo -n "Adding GPG key" \
        && sudo apt-key adv \
          --keyserver hkp://ha.pool.sks-keyservers.net:80 \
          --recv-keys 58118E89F3A912897C070ADBF76221572C52609D > /dev/null \
        && echo "$DONE" \
        && REPO="deb https://apt.dockerproject.org/repo ubuntu-xenial main" \
        && echo -n "Adding repository $REPO" \
        && echo $REPO | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
        && echo "$DONE" \
        && echo -n "Installing new packages" \
        && sudo apt-get install linux-image-extra-virtual > /dev/null \
        && echo "$DONE" \
      echo "Preparing file system for docker-engine:" \
        && DOCKER_DIR=/home/.docker \
        && echo -n "Creating directory $HOME/.docker" \
        && sudo mkdir $DOCKER_DIR \
        && echo "$DONE" \
        && echo -n "Creating symlink to $DOCKER_DIR at /var/lib/docker" \
        && sudo ln -s $DOCKER_DIR /var/lib/docker \
        && echo "$DONE" \
      echo "Installing latest version of docker-engine:" \
        && echo -n "Updating registry" \
        && sudo apt-get update > /dev/null \
        && echo "$DONE" \
        && echo -n "Installing package" \
        && sudo apt-get install -y docker-engine > /dev/null \
        && echo "$DONE" \
      echo "Adding current user to the docker group:" \
        && sudo usermod -aG docker $USER \
        && echo "$DONE" \
      return 0
      ;;
  esac

  echo "No idea how to provide Docker for Ubuntu $DISTRIB_RELEASE."
  return 1
}

echo "Docker" \
  && check_installed "docker" \
  && prerequisites \
  && echo $DONE



################################################################################
# HTOP
echo "Docker Compose" \
  && check_installed "docker-compose" \
  && sudo pip install docker-compose \
  && echo $DONE
  # && sudo curl -L "https://github.com/docker/compose/releases/download/1.9.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \



################################################################################
# HTOP
echo "HTOP" \
  && check_installed "htop" \
  && sudo apt-get install -y htop \
  && echo $DONE

################################################################################
# Tree
echo "TREE" \
  && check_installed "tree" \
  && sudo apt-get install -y tree \
  && echo $DONE



################################################################################
# Pygments
echo "Pygments" \
  && check_installed "pygmentize" \
  && sudo apt install python-pygments \
  && echo $DONE

clean_up
# https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
