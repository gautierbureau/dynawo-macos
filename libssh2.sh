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

LIBSSH2_VERSION=1.8.0
LIBSSH2_ARCHIVE=libssh2-$LIBSSH2_VERSION.tar.gz
LIBSSH2_DOWNLOAD_URL=https://www.libssh2.org/download
LIBSSH2_DIRECTORY=libssh2-$LIBSSH2_VERSION
if [ ! -f "$SCRIPT_DIR/data/$LIBSSH2_ARCHIVE" ]; then
  curl -L $LIBSSH2_DOWNLOAD_URL/$LIBSSH2_ARCHIVE --output $SCRIPT_DIR/data/$LIBSSH2_ARCHIVE || { echo "Error while downloading libssh2."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$LIBSSH2_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$LIBSSH2_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting libssh2."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$LIBSSH2_DIRECTORY
./configure CC=clang CXX=clang++ --prefix=$install_path --with-openssl --with-libssl-prefix=$openssl_path || { echo "Error while configuring libssh2."; exit 1; }
make -j $nb_proc || { echo "Error while libssh2 make."; exit 1; }
make -j $nb_proc install || { echo "Error while libssh2 make install."; exit 1; }
