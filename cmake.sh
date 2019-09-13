#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install cmake from sources
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

CMAKE_VERSION=3.12.3
CMAKE_VERSION_SHORT=3.12
CMAKE_ARCHIVE=cmake-$CMAKE_VERSION.tar.gz
CMAKE_DOWNLOAD_URL=https://cmake.org/files/v$CMAKE_VERSION_SHORT
CMAKE_DIRECTORY=cmake-$CMAKE_VERSION
if [ ! -f "$SCRIPT_DIR/data/$CMAKE_ARCHIVE" ]; then
  curl -L $CMAKE_DOWNLOAD_URL/$CMAKE_ARCHIVE --output $SCRIPT_DIR/data/$CMAKE_ARCHIVE || { echo "Error while downloading cmake."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$CMAKE_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$CMAKE_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting cmake."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$CMAKE_DIRECTORY
CC=clang CXX=clang++ ./bootstrap --prefix=$install_path || { echo "Error while bootstrap cmake."; exit 1; }
make -j $nb_proc || { echo "Error while cmake make."; exit 1; }
make -j $nb_proc install || { echo "Error while cmake make install."; exit 1; }
