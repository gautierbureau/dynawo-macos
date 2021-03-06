#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p $SCRIPT_DIR/data
mkdir -p $SCRIPT_DIR/build

usage() {
  echo -e "Usage: `basename $0` [OPTIONS]\tprogram to intall Dynawo dependencies on macOS from sources
  where OPTIONS can be one of the following:
    --prefix (-p) path           path of installation (mandatory)
    --with-sudo (-w) (yes|no)    do you have sudo privileges
    --no-pip                     skip pip install
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
    --with-sudo|-w)
      if [ "$2" = "no" -o "$2" = "yes" ]; then
        with_sudo=$2
      else
        echo "$2: invalid option with --with-sudo."
        usage
        exit 1
      fi
      shift 2
      ;;
    --no-pip)
      no_pip=yes
      shift 1
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
  usage
  exit 1
fi

install_path=$(python -c "import os; print(os.path.realpath('$install_path'))")

if [ "$SCRIPT_DIR" = "$install_path" ]; then
  echo "Install path, $install_path, should be different than script directory, $SCRIPT_DIR."
fi

[ ! -z "$with_sudo" ] && option_gfrotran="-w $with_sudo"
$SCRIPT_DIR/install_gfrotran.sh -p $install_path -j $nb_proc $option_gfrotran

$SCRIPT_DIR/install_omc.sh -p $install_path -j $nb_proc

if [ ! -x "$(command -v cmake)" ]; then
  libarchive_option="-a $install_path/bin"
  googletest_option="-a $install_path/bin"
  doxygen_option="-a $install_path/bin"
  osg_option="-a $install_path/bin"
fi

$SCRIPT_DIR/openssl.sh -p $install_path -j $nb_proc || { echo "Error while openssl install."; exit 1; }
$SCRIPT_DIR/libssh2.sh -p $install_path -j $nb_proc --openssl $install_path || { echo "Error while libssh2 install."; exit 1; }
$SCRIPT_DIR/wget.sh -p $install_path -j $nb_proc --openssl $install_path || { echo "Error while wget install."; exit 1; }

$SCRIPT_DIR/boost.sh -p $install_path -j $nb_proc || { echo "Error while boost install."; exit 1; }
$SCRIPT_DIR/libarchive.sh -p $install_path -j $nb_proc $libarchive_option || { echo "Error while libarchive install."; exit 1; }

$SCRIPT_DIR/googletest.sh -p $install_path -j $nb_proc $googletest_option || { echo "Error while googletest install."; exit 1; }
$SCRIPT_DIR/doxygen.sh -p $install_path -j $nb_proc $doxygen_option || { echo "Error while doxygen install."; exit 1; }
$SCRIPT_DIR/lcov.sh -p $install_path -j $nb_proc || { echo "Error while lcov install."; exit 1; }

$SCRIPT_DIR/help2man.sh -p $install_path -j $nb_proc || { echo "Error while help2man install."; exit 1; }
$SCRIPT_DIR/texinfo.sh -p $install_path -j $nb_proc || { echo "Error while texinfo install."; exit 1; }
$SCRIPT_DIR/icu.sh -p $install_path -j $nb_proc || { echo "Error while icu install."; exit 1; }
$SCRIPT_DIR/omniorb.sh -p $install_path -j $nb_proc || { echo "Error while omniorb install."; exit 1; }
$SCRIPT_DIR/hdf5.sh -p $install_path -j $nb_proc || { echo "Error while hdf5 install."; exit 1; }
$SCRIPT_DIR/ncurses.sh -p $install_path -j $nb_proc || { echo "Error while ncurses install."; exit 1; }
$SCRIPT_DIR/readline.sh -p $install_path -j $nb_proc || { echo "Error while readline install."; exit 1; }

$SCRIPT_DIR/osg.sh -p $install_path -j $nb_proc $osg_option || { echo "Error while OSG install."; exit 1; }

$SCRIPT_DIR/qt.sh -p $install_path -j $nb_proc || { echo "Error while qt install."; exit 1; }

if [ "$no_pip" != "yes" ]; then
  pip_path=$(find /Users/$(id -u -n)/Library/Python -type f -name "pip" | head -1)
  if [ ! -z "$pip_path" ]; then
    export PATH=$(dirname $pip_path):$PATH
    if [ -x "$(command -v pip)" ]; then
      pip_already_installed="yes"
    fi
  fi

  if [ -z "$pip_already_installed" ]; then
    echo -e "Do you want to install pip? \033[1;31m(y/n)\033[0m"
    IFS= read -r -d\0 -n 1 pip_answer
    if [ ! "$pip_answer" = $'\n' ]; then echo ; fi
    case "$pip_answer" in
      [yY])
        pip_path=$(find /Users/$(id -u -n)/Library/Python -type f -name "pip" | head -1)
        if [ ! -z "$pip_path" ]; then
          export PATH=$(dirname $pip_path):$PATH
        fi
        if [ ! -x "$(command -v pip)" ]; then
          curl -L https://bootstrap.pypa.io/get-pip.py -o $SCRIPT_DIR/data/get-pip.py
          python $SCRIPT_DIR/data/get-pip.py --user
        fi
        ;;
      [nN]|$'\n')
        ;;
      *)
        echo "$pip_answer: invalid answer."
        exit 1
        ;;
    esac
  fi

  pip_path=$(find /Users/$(id -u -n)/Library/Python -type f -name "pip" | head -1)
  if [ ! -z "$pip_path" ]; then
    export PATH=$(dirname $pip_path):$PATH
  fi
  if [ -x "$(command -v pip)" ]; then
    pip install --user lxml
    pip install --user psutil
  else
    echo "Something went wrong with pip. You need to install pip and two packages lxml and psutil."
  fi
fi

echo '#!/bin/bash
export DYNAWO_HOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

export DYNAWO_SRC_OPENMODELICA=$DYNAWO_HOME/OpenModelica/Source
export DYNAWO_INSTALL_OPENMODELICA=$DYNAWO_HOME/OpenModelica/Install

export DYNAWO_LOCALE=en_GB
export DYNAWO_RESULTS_SHOW=true
export DYNAWO_BROWSER="open -a Safari"

export DYNAWO_NB_PROCESSORS_USED=1

export DYNAWO_BUILD_TYPE=Release
export DYNAWO_CXX11_ENABLED=YES
export DYNAWO_COMPILER=CLANG
export DYNAWO_LIBRARY_TYPE=SHARED

#export DYNAWO_LIBARCHIVE_HOME='"$install_path"'
#export DYNAWO_BOOST_HOME='"$install_path"'
#export DYNAWO_GTEST_HOME='"$install_path"'
#export DYNAWO_GMOCK_HOME=$DYNAWO_GTEST_HOME

export PATH='"$install_path"'/bin:$PATH
export PATH="$(dirname $(xcrun -f llvm-cov))":$PATH

if [ "$1" = "build-omcDynawo" ]; then
  export ACLOCAL_PATH='"$install_path"'/share/aclocal:$ACLOCAL_PATH
  export LDFLAGS="-L'"$install_path"'/lib" # causes problem with boost rpath so only set for omc build
  export CPPFLAGS="-I'"$install_path"'/include"
  export CFLAGS="-isysroot $(xcrun --show-sdk-path)"
  export CXXFLAGS="-isysroot $(xcrun --show-sdk-path)"
  export CPATH=$CPATH:"$(xcrun --show-sdk-path)/usr/include"
  export JAVA_HOME='"$install_path"'/Java/'"$(ls $install_path/Java)"'/Contents/Home
fi

$DYNAWO_HOME/util/envDynawo.sh $@' > $install_path/myEnvDynawo.sh
chmod +x $install_path/myEnvDynawo.sh

echo '#!/bin/bash

export PATH='"$(find $install_path/Qt -type d -name "qtbase")"'/bin:'"$install_path"'/bin:$PATH
export BOOST_ROOT='"$install_path"'

MY_LDFLAGS="-L'"$install_path"'/lib"

MY_CPPFLAGS="-I'"$install_path"'/include"

export JAVA_HOME='"$install_path"'/Java/'"$(ls $install_path/Java)"'/Contents/Home

export CPATH=$CPATH:"$(xcrun --show-sdk-path)/usr/include":'"$install_path"'/include

autoreconf
./configure --disable-option-checking --prefix='"$install_path"'/OpenModelica CC=clang CXX=clang++ '"'"'LDFLAGS=-L'"$install_path"'/lib -L'"$(find "$install_path"/Qt -type d -name "qtbase")""/lib'"' '"'"'CPPFLAGS=-I'"$install_path"'/include -I'"$(find "$install_path"/Qt -type d -name "qtbase")"'/include'"'"' CXXFLAGS=-stdlib=libc++ --cache-file=/dev/null --srcdir=.

make -j '"$nb_proc"'
make -j '"$nb_proc"' omplot
make -j '"$nb_proc"' omedit
make -j '"$nb_proc"' omnotebook
make -j '"$nb_proc"' omshell
make -j '"$nb_proc"' omlibrary-core
make -j '"$nb_proc"' all

install_name_tool -add_rpath '"$install_path"'/lib $(find build -name "OMEdit.app")/Contents/MacOS/OMEdit' > $install_path/install_openmodelica.sh
chmod +x $install_path/install_openmodelica.sh
