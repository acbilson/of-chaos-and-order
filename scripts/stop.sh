#!/bin/bash
. .env

ENVIRONMENT=$1

case $ENVIRONMENT in

uat)
  echo "stops container in uat..."
  ssh -t ${UAT_HOST} sudo podman stop ${UAT_IMAGE_NAME}
;;

prod)
  echo "disables container in production..."
  ssh -t ${PROD_HOST} sudo systemctl disable ${IMAGE_NAME}
  ssh -t ${PROD_HOST} sudo podman stop ${IMAGE_NAME}
;;

*)
  echo "please provide one of the following as the first argument: uat, prod."
  exit 1

esac
