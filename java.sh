#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to install boost from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
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

mkdir -p $install_path

JAVA_VERSION=11.0.4_11
JAVA_ARCHIVE=OpenJDK11U-jdk_x64_mac_hotspot_$JAVA_VERSION.tar.gz
JAVA_DOWNLOAD_URL=https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11.4
if [ ! -f "$SCRIPT_DIR/data/$JAVA_ARCHIVE" ]; then
  curl -L $JAVA_DOWNLOAD_URL/$JAVA_ARCHIVE --output $SCRIPT_DIR/data/$JAVA_ARCHIVE || { echo "Error while downloading java."; exit 1; }
fi
JAVA_DIRECTORY=$(tar -tf data/OpenJDK11U-jdk_x64_mac_hotspot_$JAVA_VERSION.tar.gz | tail -1 | cut -d '/' -f 1)
if [ ! -d "$install_path/$JAVA_DIRECTORY" ]; then
  tar xzf $SCRIPT_DIR/data/$JAVA_ARCHIVE -C $install_path || { echo "Error while extracting java."; exit 1; }
fi
