#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data

GFORTRAN_VERSION=8.3
GFORTRAN_ARCHIVE=gfortran-$GFORTRAN_VERSION-bin.tar.gz
GFORTRAN_DOWNLOAD_URL=http://prdownloads.sourceforge.net/hpc
if [ ! -f "$SCRIPT_DIR/data/$GFORTRAN_ARCHIVE" ]; then
  curl -L $GFORTRAN_DOWNLOAD_URL/$GFORTRAN_ARCHIVE --output $SCRIPT_DIR/data/$GFORTRAN_ARCHIVE || { echo "Error while downloading gfortran."; exit 1; }
fi

sudo tar xzf $SCRIPT_DIR/data/$GFORTRAN_ARCHIVE -C / || { echo "Error while installing gfortran."; exit 1; }