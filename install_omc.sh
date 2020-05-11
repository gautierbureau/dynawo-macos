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

# $SCRIPT_DIR/autoconf.sh -p $install_path -j $nb_proc || { echo "Error while autoconf install."; exit 1; }
# $SCRIPT_DIR/automake.sh -p $install_path -j $nb_proc -a $install_path/bin  || { echo "Error while automake install."; exit 1; }
# $SCRIPT_DIR/pkg-config.sh -p $install_path -j $nb_proc || { echo "Error while pkg-config install."; exit 1; }
# $SCRIPT_DIR/libtool.sh -p $install_path -j $nb_proc || { echo "Error while libtool install."; exit 1; }
# [ -f "$install_path/bin/libtool" ] && mv $install_path/bin/libtool $install_path/bin/libtool.old
$SCRIPT_DIR/sed.sh -p $install_path -j $nb_proc || { echo "Error while sed install."; exit 1; }
$SCRIPT_DIR/gettext.sh -p $install_path -j $nb_proc || { echo "Error while gettext install."; exit 1; }
$SCRIPT_DIR/xz.sh -p $install_path -j $nb_proc || { echo "Error while xz install."; exit 1; }
if [ ! -x "$(command -v cmake)" ]; then
  $SCRIPT_DIR/cmake.sh -p $install_path -j $nb_proc || { echo "Error while cmake install."; exit 1; }
  expat_option="-a $install_path/bin"
fi

if [ ! -x "$(command -v cmake)" ]; then
  $SCRIPT_DIR/java.sh -p $install_path/Java || { echo "Error while java install."; exit 1; }
fi

$SCRIPT_DIR/libexpat.sh -p $install_path -j $nb_proc $expat_option || { echo "Error while libexpat install."; exit 1; }
