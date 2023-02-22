#!/usr/bin/env bash

arch=`uname -a`
if [[ "$arch" =~ "Linux" && "$arch" =~ "microsoft" ]]; then
  if [[ $(command -v python) ]]; then
    PIP="pip"
    if [[ ! $(command -v pip) ]]; then
      echo "install python-pip"
      sudo apt-get update && sudo apt -y install python-pip || { echo "install pip first"; exit 1; }
    fi
  elif [[ $(command -v python3) ]]; then
    PIP="pip3"
    if [[ ! $(command -v pip3) ]]; then
      echo "install python3-pip"
      sudo apt-get update && sudo apt -y install python3-pip || { echo "install pip3 first"; exit 1; }
    fi
  else
    echo "install python or python3"
    exit 1
  fi

  [[ $(command -v j2) ]] || {
    echo "install pyyaml & j2cli"
    sudo -H $PIP --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org install pyyaml j2cli
  } || required "pyyaml & j2cli"

  TEMPLATE_DIR=`dirname "$(readlink -f -- "$0")"`
  BASE_DIR=`readlink -f -- "$TEMPLATE_DIR/.."`
elif [[ "$arch" =~ "Darwin" ]]; then
  # Mac
  command -v greadlink >/dev/null 2>&1 || brew install coreutils || { echo "install coreutils first"; exit 1; }
  command -v j2 >/dev/null 2>&1 || pip install pyyaml j2cli || { echo "install pyyaml & j2cli first"; exit 1; }
  TEMPLATE_DIR=`dirname "$(greadlink -f -- "$0")"`
  BASE_DIR=`greadlink -f -- "$TEMPLATE_DIR/.."`
else
  echo "unsupported arch: $arch"
  exit 1
fi

if [[ "$1" == "-v" ]]; then
    VERBOSE=1
fi

TEMPLATE_FILES=`ls $TEMPLATE_DIR/docker/*.j2`

for MODULE in $(find "$BASE_DIR" -mindepth 0 -maxdepth 1 -type d)
do
    DATA_FILE="$MODULE/Dockerfile.yml"

    if [[ -f "$DATA_FILE" ]]; then
        echo "[ $MODULE ]"
        for TEMPLATE_FILE in $TEMPLATE_FILES
        do
            RESULT_FILE="$MODULE/$(basename $TEMPLATE_FILE .j2)"
            echo "- $TEMPLATE_FILE > $RESULT_FILE"
            j2 -o $RESULT_FILE $TEMPLATE_FILE $DATA_FILE
            git add $RESULT_FILE

            if [[ $VERBOSE ]]; then
                echo ">>>>>"
                cat $RESULT_FILE
                echo "\n<<<<<<\n"
            fi
        done
        echo ""
    fi
done