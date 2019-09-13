#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/build-libarchive

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install libarchive from sources
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
    --add-path|-a)
      add_path=$2
      shift 2
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

LIBARCHIVE_VERSION=3.3.3
LIBARCHIVE_ARCHIVE=libarchive-${LIBARCHIVE_VERSION}.tar.gz
LIBARCHIVE_DIRECTORY=libarchive-$LIBARCHIVE_VERSION
LIBARCHIVE_DOWNLOAD_URL=https://libarchive.org/downloads
if [ ! -f "$SCRIPT_DIR/data/$LIBARCHIVE_ARCHIVE" ]; then
  curl -L $LIBARCHIVE_DOWNLOAD_URL/$LIBARCHIVE_ARCHIVE --output $SCRIPT_DIR/data/$LIBARCHIVE_ARCHIVE || { echo "Error while downloading boost."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$LIBARCHIVE_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$LIBARCHIVE_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting libarchive."; exit 1; }
fi

pushd $SCRIPT_DIR/build-libarchive
CC=clang cmake "$SCRIPT_DIR/build/$LIBARCHIVE_DIRECTORY" \
  -DCMAKE_INSTALL_PREFIX=$install_path \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_LIBXML2=OFF \
  -DENABLE_EXPAT=OFF \
  -DENABLE_BZip2=OFF \
  -DENABLE_LZMA=OFF \
  -DENABLE_ICONV=OFF \
  -DCMAKE_MACOSX_RPATH=True \
  -DCMAKE_SKIP_BUILD_RPATH=False \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=False \
  -DCMAKE_INSTALL_RPATH=$install_path/lib \
  -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=True || { echo "Error while cmake configuration of Libarchive."; exit 1; }
make -j $nb_proc || { echo "Error while make of Libarchive."; exit 1; }
make -j $nb_proc install || { echo "Error while make install of Libarchive."; exit 1; }
