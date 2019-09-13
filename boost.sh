#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build
mkdir -p $SCRIPT_DIR/build-boost

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install boost from sources
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

BOOST_VERSION=1_69_0
BOOST_ARCHIVE=boost_${BOOST_VERSION}.tar.gz
BOOST_DIRECTORY=boost_$BOOST_VERSION
BOOST_DOWNLOAD_URL=https://sourceforge.net/projects/boost/files/boost/${BOOST_VERSION//_/.}
if [ ! -f "$SCRIPT_DIR/data/$BOOST_ARCHIVE" ]; then
  curl -L $BOOST_DOWNLOAD_URL/$BOOST_ARCHIVE --output $SCRIPT_DIR/data/$BOOST_ARCHIVE || { echo "Error while downloading boost."; exit 1; }
fi
if [ ! -d "$SCRIPT_DIR/build/$BOOST_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$BOOST_ARCHIVE -C $SCRIPT_DIR/build || { echo "Error while extracting boost."; exit 1; }
fi

if [ ! -z "$MACOSX_DEPLOYMENT_TARGET" ]; then
  CC_FLAG="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
fi

pushd $SCRIPT_DIR/build/$BOOST_DIRECTORY
./bootstrap.sh --prefix=$install_path cxxstd=11 --with-toolset=clang --with-libraries=filesystem,program_options,serialization,system,log,iostreams,atomic || { echo "Error while boost bootstrap."; exit 1; }
./b2 -d2 -j $nb_proc --build-dir=$SCRIPT_DIR/build-boost cxxflags="-std=c++11 $CC_FLAG" toolset=clang variant=release install || { echo "Error while boost b2."; exit 1; }

for file in `find $install_path/lib -name "libboost*.dylib"`; do
  install_name_tool -add_rpath $install_path/lib $file 2> /dev/null || echo -n
done
