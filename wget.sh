#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install autoconf from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
    --openssl path               path to openssl install (mandatory)
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
    --openssl)
      openssl_path=$2
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

if [ -z "$openssl_path" ]; then
  echo "--openssl option is mandatory."
  usage
  exit 1
fi

openssl_path=$(python -c "import os; print(os.path.realpath('$openssl_path'))")

WGET_VERSION=1.20
WGET_ARCHIVE=wget-$WGET_VERSION.tar.gz
WGET_DOWNLOAD_URL=https://ftp.gnu.org/gnu/wget
WGET_DIRECTORY=wget-$WGET_VERSION
if [ ! -f "$SCRIPT_DIR/data/$WGET_ARCHIVE" ]; then
  curl -L $WGET_DOWNLOAD_URL/$WGET_ARCHIVE --output $SCRIPT_DIR/data/$WGET_ARCHIVE || { echo "Error while downloading wget."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$WGET_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$WGET_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting wget."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$WGET_DIRECTORY
./configure CC=clang CXX=clang++ --prefix=$install_path --with-ssl=openssl --with-libssl-prefix=$openssl_path || { echo "Error while configuring wget."; exit 1; }
make -j $nb_proc || { echo "Error while wget make."; exit 1; }
make -j $nb_proc install || { echo "Error while wget make install."; exit 1; }
