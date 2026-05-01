#!/bin/bash
. .env

ENVIRONMENT=$1

case $ENVIRONMENT in

dev)
  # any files included in the container are moved into the /dist
  # folder. This allows the files to be templated with .env variables.
  echo "copies template files..."
  mkdir dist && \
    cp template/build-site.sh dist/build-site.sh && \
    envsubst < template/micropub.ini > dist/micropub.ini

  echo "builds development image..."
  docker build -f Dockerfile \
    --target=dev \
    --build-arg EXPOSED_PORT=${EXPOSED_PORT} \
    -t ${USER_NAME}/${DEV_IMAGE_NAME}:${IMAGE_TYPE} .
;;

uat)
  # sends files to second-level /dist folder for copying
  echo "copies template files..."
  mkdir -p dist/dist && \
    cp template/build-site.sh dist/dist/build-site.sh && \
    envsubst < template/micropub.ini > dist/dist/micropub.ini

  # Because UAT and prod are remote and use podman instead of Docker,
  # copy over all the artifacts necessary to build the image remotely.
  # Building locally fixes any issue with compatibility and arch support,
  # and I prefer it to hosting in Docker Hub.
  echo "copies files to distribute..."
  cp Dockerfile dist/

  echo "copies source code to distribute..."
  cp -r src dist/src

  echo "distributes dist/ folder..."
  scp -r dist ${UAT_HOST}:${UAT_DIST}

  echo "builds image on UAT"
  ssh -t ${UAT_HOST} \
    sudo podman build \
      -f ${UAT_DIST}/Dockerfile \
      --target=uat \
      -t ${USER_NAME}/${UAT_IMAGE_NAME}:${IMAGE_TYPE} \
      ${UAT_DIST}
;;

prod)
  echo "copies template files..."
  mkdir -p dist/dist && \
    cp template/build-site.sh dist/dist/build-site.sh && \
    envsubst < template/micropub.ini > dist/dist/micropub.ini && \
    envsubst < template/container-${IMAGE_NAME}.service > dist/container-${IMAGE_NAME}.service

  echo "copies files to distribute..."
  cp Dockerfile dist/

  echo "copies source code to distribute..."
  cp -r src dist/src

  echo "distributes dist/ folder..."
  scp -r dist ${PROD_HOST}:${PRD_DIST}

  echo "builds image on production"
  ssh -t ${PROD_HOST} \
    sudo podman build \
      -f ${PRD_DIST}/Dockerfile \
      --target=prod \
      -t ${USER_NAME}/${IMAGE_NAME}:${IMAGE_TYPE} \
      ${PRD_DIST}
;;

*)
  echo "please provide one of the following as the first argument: dev, uat, prod."
  exit 1

esac
