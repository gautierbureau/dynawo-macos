#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/build-doxygen

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install doxygen from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
    --nb-proc (-j) NUM           number of processors to use for compilation
    --add-path (-a) path         add a path to PATH
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
    --add-path|-a)
      add_path=$2
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

if [ ! -z "$add_path" ]; then
  add_path=$(python -c "import os; print(os.path.realpath('$add_path'))")
  export PATH=$add_path:$PATH
fi

if [ ! -x "$(command -v cmake)" ]; then
  echo "You need to have cmake in your PATH."
  exit 1
fi

DOXYGEN_VERSION=1_8_15
DOXYGEN_ARCHIVE=Release_$DOXYGEN_VERSION.tar.gz
DOXYGEN_DOWNLOAD_URL=https://github.com/doxygen/doxygen/archive
DOXYGEN_DIRECTORY=doxygen-Release_$DOXYGEN_VERSION
if [ ! -f "$SCRIPT_DIR/data/$DOXYGEN_ARCHIVE" ]; then
  curl -L $DOXYGEN_DOWNLOAD_URL/$DOXYGEN_ARCHIVE --output $SCRIPT_DIR/data/$DOXYGEN_ARCHIVE || { echo "Error while downloading doxygen."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$DOXYGEN_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$DOXYGEN_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting doxygen."; exit 1; }
fi

pushd $SCRIPT_DIR/build-doxygen
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$install_path $SCRIPT_DIR/build/$DOXYGEN_DIRECTORY
make -j $nb_proc || { echo "Error while doxygen make."; exit 1; }
make -j $nb_proc install || { echo "Error while doxygen make install."; exit 1; }
