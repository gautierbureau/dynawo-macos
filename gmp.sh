#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to intall gmp from sources
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

GMP_VERSION=6.1.2
GMP_ARCHIVE=gmp-$GMP_VERSION.tar.xz
GMP_DOWNLOAD_URL=https://gmplib.org/download/gmp
GMP_DIRECTORY=gmp-$GMP_VERSION
if [ ! -f "$SCRIPT_DIR/data/$GMP_ARCHIVE" ]; then
  curl -L $GMP_DOWNLOAD_URL/$GMP_ARCHIVE --output $SCRIPT_DIR/data/$GMP_ARCHIVE || { echo "Error while downloading gmp."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$GMP_DIRECTORY" ]; then
  tar xjf $SCRIPT_DIR/data/$GMP_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting gmp."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$GMP_DIRECTORY
./configure CC=clang CXX=clang++ --prefix=$install_path --enable-cxx --with-pic --build=`uname -m`-apple-darwin`uname -r`|| { echo "Error while configuring gmp."; exit 1; }
make -j $nb_proc || { echo "Error while gmp make."; exit 1; }
make install -j $nb_proc || { echo "Error while gmp make install."; exit 1; }
