#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install sed from sources
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

SED_VERSION=4.7
SED_ARCHIVE=sed-$SED_VERSION.tar.xz
SED_DOWNLOAD_URL=https://ftp.gnu.org/gnu/sed
SED_DIRECTORY=sed-$SED_VERSION
if [ ! -f "$SCRIPT_DIR/data/$SED_ARCHIVE" ]; then
  curl -L $SED_DOWNLOAD_URL/$SED_ARCHIVE --output $SCRIPT_DIR/data/$SED_ARCHIVE || { echo "Error while downloading sed."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$SED_DIRECTORY" ]; then
  tar xJf $SCRIPT_DIR/data/$SED_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting sed."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$SED_DIRECTORY
./configure CC=clang CXX=clang++ --prefix=$install_path || { echo "Error while configuring sed."; exit 1; }
make -j $nb_proc || { echo "Error while sed make."; exit 1; }
make -j $nb_proc install || { echo "Error while sed make install."; exit 1; }

if [ ! -f "$install_path/bin/gsed" ]; then
  ln -s $install_path/bin/sed $install_path/bin/gsed || { echo "Error while symbolic link for sed."; exit 1; }
fi
