#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install autoconf from sources
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

HELP2MAN_VERSION=1.47.8
HELP2MAN_ARCHIVE=help2man-$HELP2MAN_VERSION.tar.xz
HELP2MAN_DOWNLOAD_URL=http://ftp.igh.cnrs.fr/pub/gnu/help2man
HELP2MAN_DIRECTORY=help2man-$HELP2MAN_VERSION
if [ ! -f "$SCRIPT_DIR/data/$HELP2MAN_ARCHIVE" ]; then
  curl -L $HELP2MAN_DOWNLOAD_URL/$HELP2MAN_ARCHIVE --output $SCRIPT_DIR/data/$HELP2MAN_ARCHIVE || { echo "Error while downloading help2man."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$HELP2MAN_DIRECTORY" ]; then
  tar xJf $SCRIPT_DIR/data/$HELP2MAN_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting help2man."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$HELP2MAN_DIRECTORY
./configure CC=clang CXX=clang++ --prefix=$install_path || { echo "Error while configuring help2man."; exit 1; }
make -j $nb_proc || { echo "Error while help2man make."; exit 1; }
make -j $nb_proc install || { echo "Error while help2man make install."; exit 1; }
