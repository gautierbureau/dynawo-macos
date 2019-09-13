#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install gettext from sources
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
  echo "--prefix option is mandatory."
  usage
  exit 1
fi

install_path=$(python -c "import os; print(os.path.realpath('$install_path'))")

GETTEXT_VERSION=0.20.1
GETTEXT_ARCHIVE=gettext-$GETTEXT_VERSION.tar.gz
GETTEXT_DOWNLOAD_URL=https://ftp.gnu.org/pub/gnu/gettext
GETTEXT_DIRECTORY=gettext-$GETTEXT_VERSION
if [ ! -f "$SCRIPT_DIR/data/$GETTEXT_ARCHIVE" ]; then
  curl -L $GETTEXT_DOWNLOAD_URL/$GETTEXT_ARCHIVE --output $SCRIPT_DIR/data/$GETTEXT_ARCHIVE || { echo "Error while downloading gettext."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$GETTEXT_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$GETTEXT_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting gettext."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$GETTEXT_DIRECTORY
./configure CC=clang CXX=clang++ --prefix=$install_path || { echo "Error while configuring gettext."; exit 1; }
make -j $nb_proc || { echo "Error while gettext make."; exit 1; }
make -j $nb_proc install || { echo "Error while gettext make install."; exit 1; }
