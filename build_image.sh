#!/bin/bash -e

###############
#  constants  #
###############

BUILDER_NAME=apple-baker
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
  echo "usage: $PROGRAM [-h] [-o OUTPUT_DIR] [-p PROXY] [-y] <image>"
  exit 0
}

# for macOS compatibility
realpath() {
  [[ $1 == /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

build_baker_image() {
  cd "${CUR_DIR}"
  docker inspect "${BUILDER_NAME}:${BUILDER_VERSION}" >/dev/null 2>&1 ||
    docker build -t "${BUILDER_NAME}:${BUILDER_VERSION}" tools/baker
}

################
#  initialize  #
################

# args from cli
IMAGE=
OUTPUT_DIR=${DEFAULT_OUTPUT_DIR}
PROXY=
YES=

# parse args
# from https://stackoverflow.com/a/29754866
while [[ $# -gt 0 ]]; do
  key="$1"

  case "${key}" in
  -h | --help)
    print_help
    exit 0
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
  -y)
    YES="true"
    shift # past argument
    ;;
  *) # unknown option
    IMAGE="$1" # assume it's the image
    shift      # past argument
    ;;
  esac
done

# check args
if [[ -z "${IMAGE}" ]]; then
  echo "image mustn't be empty!"
  print_help
  exit 1
fi
if [[ -z "${OUTPUT_DIR}" ]]; then
  echo "output dir mustn't be empty!"
  print_help
  exit 1
fi

# load image metadata
IMAGE_DIR="${CUR_DIR}/images/${IMAGE}"
IMAGE_CONFIG_PATH="${IMAGE_DIR}/image.sh"
if [[ ! -f "${IMAGE_CONFIG_PATH}" ]]; then
  echo "image config does not exist!"
  print_help
  exit 1
fi
source "${IMAGE_CONFIG_PATH}"

# generate output settings
OUTPUT_DIR="$(realpath "${OUTPUT_DIR}")"
mkdir -p "${OUTPUT_DIR}"
OUTPUT_IMAGE_FILENAME="${IMAGE_NAME}-${IMAGE_VERSION}.gz"
OUTPUT_IMAGE_PATH="${OUTPUT_DIR}/${OUTPUT_IMAGE_FILENAME}"

# final confirmation
echo "[IMAGE]     ${IMAGE_NAME}"
echo "[VERSION]   ${IMAGE_VERSION}"
echo "[SIZE]      ${IMAGE_SIZE} MB"
echo "[OUTPUT]    ${OUTPUT_IMAGE_PATH}"
echo
if [ -z "${YES}" ]; then
  echo "enter to continue"
  read
fi

###########
#  build  #
###########

build_baker_image

BUILD_VOLUMES=(
  "-v" "/dev:/dev"
  "-v" "${IMAGE_DIR}/scripts:/scripts:ro"
  "-v" "${OUTPUT_DIR}:/output"
)
BUILD_ENVS=(
  "-e" "BUILD_SCRIPTS=/scripts"
  "-e" "BUILD_OUTPUT=/output/${OUTPUT_IMAGE_FILENAME}"
  "-e" "BUILD_IMAGE_SIZE=${IMAGE_SIZE}"
  "-e" "BUILD_OS_DISTRO=${OS_DISTRO}"
  "-e" "BUILD_OS_VERSION=${OS_VERSION}"
  "-e" "BUILD_APT_MIRROR=${APT_MIRROR}"
)
if [[ -n "${PROXY}" ]]; then
  BUILD_ENVS+=("-e" "http_proxy=${PROXY}" "-e" "https_proxy=${PROXY}")
fi
T_ARG="-i"
[ -t 0 ] && T_ARG="-it"
docker run "${T_ARG}" --rm --privileged --cap-add=ALL "${BUILD_VOLUMES[@]}" "${BUILD_ENVS[@]}" "${BUILDER_NAME}:${BUILDER_VERSION}"

echo
echo "image successfully built at ${OUTPUT_IMAGE_PATH}"
