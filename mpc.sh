#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to intall mpc from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
    --nb-proc (-j) NUM           number of processors to use for compilation
    --gmp path                   path to gmp install (mandatory)
    --mpfr path                  path to mpfr install (mandatory)
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
    --mpfr)
      mpfr_path=$2
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

if [ -z "$mpfr_path" ]; then
  echo "--mpfr option is mandatory."
  usage
  exit 1
fi

mpfr_path=$(python -c "import os; print(os.path.realpath('$mpfr_path'))")

LIBMPC_VERSION=1.1.0
LIBMPC_ARCHIVE=mpc-$LIBMPC_VERSION.tar.gz
LIBMPC_DOWNLOAD_URL=https://ftp.gnu.org/gnu/mpc
LIBMPC_DIRECTORY=mpc-$LIBMPC_VERSION
if [ ! -f "$SCRIPT_DIR/data/$LIBMPC_ARCHIVE" ]; then
  curl -L $LIBMPC_DOWNLOAD_URL/$LIBMPC_ARCHIVE --output $SCRIPT_DIR/data/$LIBMPC_ARCHIVE || { echo "Error while downloading libmpc."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$LIBMPC_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$LIBMPC_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting mpc."; exit 1; }
fi

pushd $SCRIPT_DIR/build/$LIBMPC_DIRECTORY
CC=clang ./configure --prefix=$install_path --with-gmp=$gmp_path --with-mpfr=$mpfr_path || { echo "Error while configuring libmpc."; exit 1; }
make -j $nb_proc || { echo "Error while libmpc make."; exit 1; }
make -j $nb_proc install || { echo "Error while libmpc make install."; exit 1; }
