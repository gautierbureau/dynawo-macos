#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/build-googletest

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install googletest from sources
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

GTEST_VERSION=1.8.1
GTEST_ARCHIVE=release-${GTEST_VERSION}.tar.gz
GTEST_DIRECTORY=googletest-release-$GTEST_VERSION
GTEST_DOWNLOAD_URL=https://github.com/google/googletest/archive
if [ ! -f "$SCRIPT_DIR/data/$GTEST_ARCHIVE" ]; then
  curl -L $GTEST_DOWNLOAD_URL/$GTEST_ARCHIVE --output $SCRIPT_DIR/data/$GTEST_ARCHIVE || { echo "Error while downloading GoogleTest."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$GTEST_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$GTEST_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting googletest."; exit 1; }
fi

pushd $SCRIPT_DIR/build-googletest
CC=clang CXX=clang++ cmake "$SCRIPT_DIR/build/$GTEST_DIRECTORY" \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_INSTALL_PREFIX=$install_path \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-std=c++11" \
  -DCMAKE_MACOSX_RPATH=True \
  -DCMAKE_SKIP_BUILD_RPATH=False \
  -DCMAKE_BUILD_WITH_INSTALL_RPATH=False \
  -DCMAKE_INSTALL_RPATH=$install_path/lib \
  -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=True || { echo "Error while cmake configuration of GoogleTest."; exit 1; }
make -j $nb_proc || { echo "Error while GoogleTest make."; exit 1; }
make -j $nb_proc install || { echo "Error while GoogleTest make install."; exit 1; }
