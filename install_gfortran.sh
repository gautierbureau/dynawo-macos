#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to intall Dynawo dependencies on macOS from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
    --with-sudo (-w) (yes|no)    do you have sudo privileges
    --nb-proc (-j) NUM           number of processors to use for compilation
    --help (-h)                  print this message.
"
}

nb_proc=1

while (($#)); do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --prefix|-p)
      install_path=$2
      shift 2
      ;;
    --with-sudo|-w)
      if [ "$2" = "no" -o "$2" = "yes" ]; then
        with_sudo=$2
      else
        echo "$2: invalid option with --with-sudo."
        usage
        exit 1
      fi
      shift 2
      ;;
    --nb-proc|-j)
      case $2 in
        [0-9]*)
          nb_proc=$2
          shift 2
          ;;
        *)
          echo "$2: invalid value for -j."
          usage
          exit 1
          ;;
      esac
      ;;
    *)
      echo "$1: invalid option."
      usage
      exit 1
      ;;
  esac
done

if [ -z "$install_path" ]; then
  usage
  exit 1
fi

install_path=$(python -c "import os; print(os.path.realpath('$install_path'))")

if [ "$SCRIPT_DIR" = "$install_path" ]; then
  echo "Install path, $install_path, should be different than script directory, $SCRIPT_DIR."
fi

if [ -z "$with_sudo" ]; then
  echo -e "Do you have sudo privileges? \033[1;31m(y/n)\033[0m"
  echo "  yes: we will install a precompiled gfortran (from http://hpc.sourceforge.net) in /usr/local. It means you will need to have /usr/local/bin in your PATH environment variable."
  echo "  no: we will install a local gfortran from sources but it may take some time to compile. If you don't want to install gfortran in the default path use this option."

  IFS= read -r -d\0 -n 1 sudo_answer
  if [ ! "$sudo_answer" = $'\n' ]; then echo ; fi
  case "$sudo_answer" in
    [yY])
      with_sudo="yes"
      ;;
    [nN]|$'\n')
      with_sudo="no"
      ;;
    *)
      echo "$sudo_answer: invalid answer."
      ;;
  esac
fi

if [ "$with_sudo" = "yes" ]; then
  if [ -z "$(echo $PATH | grep -o '/usr/local/bin')" ]; then
    echo "You need to add /usr/local/bin in your PATH."
    exit 1
  fi
fi

if [ "$with_sudo" = "yes" ]; then
  $SCRIPT_DIR/gfortran_sudo.sh || { echo "Error while gfortran install with sudo."; exit 1; }
else
  $SCRIPT_DIR/gmp.sh -p $install_path -j $nb_proc || { echo "Error while gmp install."; exit 1; }
  $SCRIPT_DIR/mpfr.sh -p $install_path -j $nb_proc --gmp $install_path || { echo "Error while gmp install."; exit 1; }
  $SCRIPT_DIR/mpc.sh -p $install_path -j $nb_proc --gmp $install_path --mpfr $install_path || { echo "Error while mpc install."; exit 1; }
  $SCRIPT_DIR/isl.sh -p $install_path -j $nb_proc --gmp $install_path || { echo "Error while isl install."; exit 1; }
  $SCRIPT_DIR/gfortran.sh -p $install_path -j $nb_proc --gmp $install_path --mpfr $install_path --mpc $install_path --isl $install_path || { echo "Error while gfortran install."; exit 1; }
fi
