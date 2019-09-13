#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install qt from sources
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

mkdir -p $install_path/Qt

QT_VERSION=5.4.0
QT_VERSION_SHORT=5.4
QT_DOWNLOAD_URL=http://download.qt.io/archive/qt/$QT_VERSION_SHORT/$QT_VERSION/single
QT_DIRECTORY=qt-everywhere-opensource-src-${QT_VERSION}
QT_ARCHIVE=${QT_DIRECTORY}.tar.xz

if [ ! -f "$SCRIPT_DIR/data/$QT_ARCHIVE" ]; then
  curl -L $QT_DOWNLOAD_URL/$QT_ARCHIVE -o $SCRIPT_DIR/data/$QT_ARCHIVE || { echo "Error while downloading qt."; exit 1; }
fi
if [ ! -d "$install_path/Qt/$QT_DIRECTORY" ]; then
  tar xJf $SCRIPT_DIR/data/$QT_ARCHIVE -C $install_path/Qt || { echo "Error while extracting qt."; exit 1; }
fi

if [ -d "$install_path/Qt/$QT_DIRECTORY" ]; then
  cp $SCRIPT_DIR/qt_patches/$QT_VERSION/*.patch $install_path/Qt/$QT_DIRECTORY
else
  echo "Extraction went wrong."; exit 1;
fi

pushd $install_path/Qt/$QT_DIRECTORY

if ! patch -R -d qtbase -p2 -s -f --dry-run < configure_qtbase.patch > /dev/null 2>&1; then
  patch -d qtbase -p2 < configure_qtbase.patch || { echo "Error while patching qt."; exit 1; }
fi

if ! patch -R -d qtwebkit -p2 -s -f --dry-run < qtwebkit.patch > /dev/null 2>&1; then
  patch -d qtwebkit -p2 < qtwebkit.patch || { echo "Error while patching qt."; exit 1; }
fi

if ! patch -R -d qtbase/src -p2 -s -f --dry-run < first.patch > /dev/null 2>&1; then
  patch -d qtbase/src -p2 < first.patch || { echo "Error while patching qt."; exit 1; }
fi

if ! patch -R -d qtbase/src -p2 -s -f --dry-run < second.patch > /dev/null 2>&1; then
  patch -d qtbase/src -p2 < second.patch || { echo "Error while patching qt."; exit 1; }
fi

if ! patch -R -d qtbase/src -p2 -s -f --dry-run < third.patch > /dev/null 2>&1; then
  patch -d qtbase/src -p2 < third.patch || { echo "Error while patching qt."; exit 1; }
fi

if ! patch -R -d qtbase/src -p2 -s -f --dry-run < fourth.patch > /dev/null 2>&1; then
  patch -d qtbase/src -p2 < fourth.patch || { echo "Error while patching qt."; exit 1; }
fi

./configure -v -prefix $install_path/Qt/$QT_DIRECTORY/qtbase -release -opensource -nomake tests -nomake examples -platform macx-clang -confirm-license -c++11 || { echo "Error while configuring qt."; exit 1; }
make -j $nb_proc || { echo "Error while make qt."; exit 1; }
