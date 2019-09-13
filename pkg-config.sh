#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install pkg-config from sources
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

PKG_CONFIG_VERSION=0.29.2
PKG_CONFIG_ARCHIVE=pkg-config-$PKG_CONFIG_VERSION.tar.gz
PKG_CONFIG_DOWNLOAD_URL=https://pkg-config.freedesktop.org/releases
PKG_CONFIG_DIRECTORY=pkg-config-$PKG_CONFIG_VERSION
if [ ! -f "$SCRIPT_DIR/data/$PKG_CONFIG_ARCHIVE" ]; then
  curl -L $PKG_CONFIG_DOWNLOAD_URL/$PKG_CONFIG_ARCHIVE --output $SCRIPT_DIR/data/$PKG_CONFIG_ARCHIVE || { echo "Error while downloading pkg-config."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$PKG_CONFIG_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$PKG_CONFIG_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting pkg-config."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$PKG_CONFIG_DIRECTORY
./configure CC=clang CXX=clang++ --with-internal-glib --prefix=$install_path || { echo "Error while configuring pkg-config."; exit 1; }
make -j $nb_proc || { echo "Error while pkg-config make."; exit 1; }
make -j $nb_proc install || { echo "Error while pkg-config make install."; exit 1; }
