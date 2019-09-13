#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to intall isl from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
    --nb-proc (-j) NUM           number of processors to use for compilation
    --gmp path                   path to gmp install (mandatory)
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
    --gmp)
      gmp_path=$2
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

if [ -z "$gmp_path" ]; then
    echo "--gmp option is mandatory."
    usage
    exit 1
fi

gmp_path=$(python -c "import os; print(os.path.realpath('$gmp_path'))")

ISL_VERSION=0.21
ISL_ARCHIVE=isl-$ISL_VERSION.tar.xz
ISL_DOWNLOAD_URL=http://isl.gforge.inria.fr
ISL_DIRECTORY=isl-$ISL_VERSION
if [ ! -f "$SCRIPT_DIR/data/$ISL_ARCHIVE" ]; then
  curl -L $ISL_DOWNLOAD_URL/$ISL_ARCHIVE --output $SCRIPT_DIR/data/$ISL_ARCHIVE || { echo "Error while downloading isl."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$ISL_DIRECTORY" ]; then
  tar xjf $SCRIPT_DIR/data/$ISL_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting isl."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$ISL_DIRECTORY
CC=clang CXX=clang++ ./configure --prefix=$install_path --disable-dependency-tracking --disable-silent-rules --with-gmp=system --with-gmp-prefix=$gmp_path || { echo "Error while configuring isl."; exit 1; }
make -j $nb_proc || { echo "Error while isl make."; exit 1; }
make -j $nb_proc install || { echo "Error while isl make install."; exit 1; }
