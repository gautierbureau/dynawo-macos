#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to intall Dynawo dependencies on macOS from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
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

$SCRIPT_DIR/autoconf.sh -p $install_path -j $nb_proc || { echo "Error while autoconf install."; exit 1; }
$SCRIPT_DIR/automake.sh -p $install_path -j $nb_proc -a $install_path/bin  || { echo "Error while automake install."; exit 1; }
$SCRIPT_DIR/pkg-config.sh -p $install_path -j $nb_proc || { echo "Error while pkg-config install."; exit 1; }
$SCRIPT_DIR/libtool.sh -p $install_path -j $nb_proc || { echo "Error while libtool install."; exit 1; }
[ -f "$install_path/bin/libtool" ] && mv $install_path/bin/libtool $install_path/bin/libtool.old
$SCRIPT_DIR/sed.sh -p $install_path -j $nb_proc || { echo "Error while sed install."; exit 1; }
$SCRIPT_DIR/openssl.sh -p $install_path -j $nb_proc || { echo "Error while openssl install."; exit 1; }
$SCRIPT_DIR/gettext.sh -p $install_path -j $nb_proc || { echo "Error while gettext install."; exit 1; }
$SCRIPT_DIR/xz.sh -p $install_path -j $nb_proc || { echo "Error while xz install."; exit 1; }
$SCRIPT_DIR/cmake.sh -p $install_path -j $nb_proc || { echo "Error while cmake install."; exit 1; }

$SCRIPT_DIR/java.sh -p $install_path/Java || { echo "Error while java install."; exit 1; }

$SCRIPT_DIR/help2man.sh -p $install_path -j $nb_proc || { echo "Error while help2man install."; exit 1; }
$SCRIPT_DIR/texinfo.sh -p $install_path -j $nb_proc || { echo "Error while texinfo install."; exit 1; }
$SCRIPT_DIR/icu.sh -p $install_path -j $nb_proc || { echo "Error while icu install."; exit 1; }
$SCRIPT_DIR/omniorb.sh -p $install_path -j $nb_proc || { echo "Error while omniorb install."; exit 1; }
$SCRIPT_DIR/hdf5.sh -p $install_path -j $nb_proc || { echo "Error while hdf5 install."; exit 1; }

$SCRIPT_DIR/libssh2.sh -p $install_path -j $nb_proc --openssl $install_path || { echo "Error while libssh2 install."; exit 1; }
$SCRIPT_DIR/wget.sh -p $install_path -j $nb_proc --openssl $install_path || { echo "Error while wget install."; exit 1; }

$SCRIPT_DIR/libexpat.sh -p $install_path -j $nb_proc -a $install_path/bin || { echo "Error while libexpat install."; exit 1; }
$SCRIPT_DIR/ncurses.sh -p $install_path -j $nb_proc || { echo "Error while ncurses install."; exit 1; }
$SCRIPT_DIR/readline.sh -p $install_path -j $nb_proc || { echo "Error while readline install."; exit 1; }
