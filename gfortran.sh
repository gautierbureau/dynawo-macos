#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build
if [ -d "$SCRIPT_DIR/build-gfortran" ]; then
  rm -rf $SCRIPT_DIR/build-gfortran
fi
mkdir -p $SCRIPT_DIR/build-gfortran

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to intall gfortran from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
    --nb-proc (-j) NUM           number of processors to use for compilation
    --gmp path                   path to gmp install (mandatory)
    --mpfr path                  path to mpfr install (mandatory)
    --mpc path                   path to mpc install (mandatory)
    --isl path                   path to isl install (mandatory)
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
    --mpc)
      mpc_path=$2
      shift 2
      ;;
    --isl)
      isl_path=$2
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

if [ -z "$mpc_path" ]; then
  echo "--mpc option is mandatory."
  usage
  exit 1
fi

mpc_path=$(python -c "import os; print(os.path.realpath('$mpc_path'))")

if [ -z "$isl_path" ]; then
  echo "--isl option is mandatory."
  usage
  exit 1
fi

isl_path=$(python -c "import os; print(os.path.realpath('$isl_path'))")

GCC_VERSION=8.3.0
GCC_ARCHIVE=gcc-$GCC_VERSION.tar.xz
GCC_DOWNLOAD_URL=https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION
GCC_DIRECTORY=gcc-$GCC_VERSION
if [ ! -f "$SCRIPT_DIR/data/$GCC_ARCHIVE" ]; then
  curl -L $GCC_DOWNLOAD_URL/$GCC_ARCHIVE --output $SCRIPT_DIR/data/$GCC_ARCHIVE || { echo "Error while downloading gcc."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$GCC_DIRECTORY" ]; then
  tar xjf $SCRIPT_DIR/data/$GCC_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting gcc."; exit 1; }
fi

patch_file=$GCC_VERSION-xcode-bug-_Atomic-fix.patch
patch_url=https://raw.githubusercontent.com/Homebrew/formula-patches/master/gcc
if [ ! -f "$SCRIPT_DIR/data/$patch_file" ]; then
  curl -L $patch_url/$patch_file --output $SCRIPT_DIR/data/$patch_file || { echo "Error while downloading gcc patch."; exit 1; }
fi

if ! patch -R -d $SCRIPT_DIR/build -p0 -s -f --dry-run < $SCRIPT_DIR/data/$GCC_VERSION-xcode-bug-_Atomic-fix.patch > /dev/null 2>&1; then
  patch -d $SCRIPT_DIR/build -N -p0 -i $SCRIPT_DIR/data/$GCC_VERSION-xcode-bug-_Atomic-fix.patch || { echo "Error while patching gcc."; exit 1; }
fi

pushd $SCRIPT_DIR/build-gfortran
$SCRIPT_DIR/build/$GCC_DIRECTORY/configure --prefix=$install_path \
  --build=`uname -m`-apple-darwin`uname -r | cut -d . -f 1` \
  --disable-nls \
  --enable-checking=release \
  --enable-languages=fortran \
  --with-gmp=$gmp_path \
  --with-mpfr=$mpfr_path \
  --with-mpc=$mpc_path \
  --with-isl=$isl_path \
  --with-system-zlib \
  --disable-multilib \
  --with-native-system-header-dir=/usr/include \
  --with-sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk || { echo "Error while configuring gcc."; exit 1; }
make -j $nb_proc || { echo "Error while gcc make."; exit 1; }
make -j $nb_proc install || { echo "Error while gcc make install."; exit 1; }
