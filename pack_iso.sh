#!/bin/bash -e

###############
#  constants  #
###############

BUILDER_NAME=apple-burner
BUILDER_VERSION=1.0.0
DEFAULT_OUTPUT_DIR=output
PROGRAM="$0"
CUR_DIR="$(
  cd "$(dirname "$0")"
  pwd
)"

###############
#  functions  #
###############

print_help() {
  echo "usage: $PROGRAM [-h] [-c CLOUD_INIT] [-o OUTPUT_DIR] [-p PROXY] <image> <machine>"
  exit 0
}

# for macOS compatibility
realpath() {
  [[ $1 == /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

build_burner_image() {
  cd "${CUR_DIR}"
  docker inspect "${BUILDER_NAME}:${BUILDER_VERSION}" 2>&1 >/dev/null || \
    docker build -t "${BUILDER_NAME}:${BUILDER_VERSION}" --build-arg "PROXY=${PROXY}" tools/burner
}

################
#  initialize  #
################

# args from cli
IMAGE=
MACHINE=
OUTPUT_DIR=${DEFAULT_OUTPUT_DIR}
PROXY=

# parse args
# from https://stackoverflow.com/a/29754866
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case "${key}" in
  -h | --help)
    print_help
    exit 0
    ;;
  -c | --cloud-init)
    CLOUD_INIT="$2"
    shift # past argument
    shift # past value
    ;;
  -o | --output)
    OUTPUT_DIR="$2"
    shift # past argument
    shift # past value
    ;;
  -p | --proxy)
    PROXY="$2"
    shift # past argument
    shift # past value
    ;;
  *) # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift              # past argument
    ;;
  esac
done

set -- "${POSITIONAL[@]}"

IMAGE="$1"
MACHINE="$2"

# check parameters
if [[ -z "${IMAGE}" ]]; then
  echo "image mustn't be empty!"
  print_help
  exit 1
elif [[ ! -f "${IMAGE}" ]]; then
  echo "image does not exist!"
  print_help
  exit 1
fi
if [[ -z "${MACHINE}" ]]; then
  echo "machine mustn't be empty"
  print_help
  exit 1
fi
if [[ -z "${OUTPUT_DIR}" ]]; then
  echo "output dir mustn't be empty!"
  print_help
  exit 1
fi

MACHINE_DIR="${CUR_DIR}/machines/${MACHINE}"
if [[ ! -d "${MACHINE_DIR}" ]]; then
  echo "machine does not exist!"
  print_help
  exit 1
fi

if [[ -n "${CLOUD_INIT}" ]]; then
  CLOUD_INIT_DIR="${CUR_DIR}/cloud-init/${CLOUD_INIT}"
  if [[ ! -d ${CLOUD_INIT_DIR} ]]; then
    echo "cloud-init dir does not exist!"
    print_help
    exit 1
  fi
fi

# generate output settings
IMAGE="$(realpath "${IMAGE}")"
OUTPUT_DIR="$(realpath "${OUTPUT_DIR}")"
mkdir -p "${OUTPUT_DIR}"
OUTPUT_ISO_FILENAME="$(basename "${IMAGE%.gz}.iso")"
OUTPUT_ISO_PATH="${OUTPUT_DIR}/${OUTPUT_ISO_FILENAME}"

# final confirmation
echo "[MACHINE]   ${MACHINE}"
echo "[IMAGE]     ${IMAGE}"
echo "[OUTPUT]    ${OUTPUT_ISO_PATH}"
echo
echo "enter to continue"
read

###########
#  build  #
###########

build_burner_image

BUILD_VOLUMES=(
  "-v" "${MACHINE_DIR}:/scripts:ro"
  "-v" "${OUTPUT_DIR}:/output"
  "-v" "${IMAGE}:/opt/mll/work/overlay_rootfs/sys.gz:ro"
)
BUILD_ENVS=(
  "-e" "PACK_SCRIPTS=/scripts"
  "-e" "PACK_OUTPUT=/output/${OUTPUT_ISO_FILENAME}"
)
if [[ -n "${CLOUD_INIT_DIR}" ]]; then
  BUILD_VOLUMES+=("-v" "${CLOUD_INIT_DIR}:/cloud-init")
  BUILD_ENVS+=("-e" "PACK_CLOUD_INIT=/cloud-init")
fi
if [[ -n "${PROXY}" ]]; then
  BUILD_ENVS+=("-e" "http_proxy=${PROXY}" "-e" "https_proxy=${PROXY}")
fi
docker run -i --rm --privileged --cap-add=ALL "${BUILD_VOLUMES[@]}" "${BUILD_ENVS[@]}" "${BUILDER_NAME}:${BUILDER_VERSION}"

echo
echo "iso successfully built at ${OUTPUT_ISO_PATH}"
