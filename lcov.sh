#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
    echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install lcov from sources
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

LCOV_VERSION=1.13
LCOV_ARCHIVE=lcov-$LCOV_VERSION.tar.gz
LCOV_DIRECTORY=lcov-$LCOV_VERSION
LCOV_DOWNLOAD_URL=https://downloads.sourceforge.net/ltp
if [ ! -f "$SCRIPT_DIR/data/$LCOV_ARCHIVE" ]; then
  curl -L $LCOV_DOWNLOAD_URL/$LCOV_ARCHIVE --output $SCRIPT_DIR/data/$LCOV_ARCHIVE || { echo "Error while downloading lcov."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$LCOV_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$LCOV_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting lcov."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$LCOV_DIRECTORY
DESTDIR=$install_path make -j $nb_proc install || { echo "Error while lcov make install."; exit 1; }
mv $install_path/usr/local/bin/* $install_path/bin
mkdir -p $install_path/etc
mv $install_path/usr/local/etc/* $install_path/etc
mv $install_path/usr/local/share/man/man1/* $install_path/share/man/man1
mv $install_path/usr/local/share/man/man5/* $install_path/share/man/man5
rm -rf $install_path/usr
