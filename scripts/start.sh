#!/bin/bash
. .env

ENVIRONMENT=$1

case $ENVIRONMENT in

dev)
  echo "starting local development container"
  echo "------------------------------------"
  echo "container name is ${USER_NAME}/${DEV_IMAGE_NAME}:${IMAGE_TYPE}"
  echo "src path is ${CODE_SOURCE_SRC}"
  echo "dst path is ${CODE_SOURCE_DST}"
  echo "on exposed port ${EXPOSED_PORT}"
  docker run --rm \
    --expose ${EXPOSED_PORT} -p ${EXPOSED_PORT}:${CONTAINER_PORT} \
    -e "CONTENT_PATH=${DEV_CONTENT_PATH}" \
    -v ${CODE_SOURCE_SRC}:${CODE_SOURCE_DST} \
    -v ${DEV_CONTENT_SRC}:${CONTENT_DST} \
    --name ${IMAGE_NAME} \
    ${USER_NAME}/${DEV_IMAGE_NAME}:${IMAGE_TYPE}
;;

# I run uat/prod with podman, not Docker. This will start the container remotely
# Note: commands run removely via ssh -t must be run one-at-a-time.
uat)
  echo "starts container in UAT..."
  ssh -t ${UAT_HOST} \
    sudo podman run --rm -d \
    --expose ${EXPOSED_PORT} -p ${EXPOSED_PORT}:${CONTAINER_PORT} \
    -e "CONTENT_PATH=${UAT_CONTENT_PATH}" \
    -v ${UAT_CONTENT_SRC}:${CONTENT_DST} \
    --name ${UAT_IMAGE_NAME} \
  ${USER_NAME}/${UAT_IMAGE_NAME}:${IMAGE_TYPE}
;;

# Podman containers can be run with systemd services for all the reliability
# of a production service without the Docker daemon.
prod)
  echo "enabling production service..."
  ssh -t ${PROD_HOST} sudo systemctl daemon-reload
  ssh -t ${PROD_HOST} sudo systemctl enable --now container-${IMAGE_NAME}.service
;;

*)
  echo "please provide one of the following as the first argument: dev, uat, prod."
  exit 1

esac
