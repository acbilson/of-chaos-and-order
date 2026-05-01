#!/bin/bash
. .env

ENVIRONMENT=$1

case $ENVIRONMENT in

dev)
  # runs a test command in the development container so a second
  # container is not necessary.
  # entrypoint args must come after image name (weird)
  docker run --rm \
    -v ${CODE_SOURCE_SRC}:${CODE_SOURCE_DST} \
    -v ${DEV_CONTENT_SRC}:${CONTENT_DST} \
    --name ${TST_IMAGE_NAME} \
    --entrypoint "python" \
    ${USER_NAME}/${DEV_IMAGE_NAME}:${IMAGE_TYPE}
    -m unittest discover tests
  ;;

*)
  echo "please provide one of the following as the first argument: dev."
  exit 1

esac
