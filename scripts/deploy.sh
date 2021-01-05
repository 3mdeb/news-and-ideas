#!/bin/bash -x

case "${TRAVIS_BRANCH}" in
  "master")
    FTP_DIR="${FTP_DIR_PROD}"
      ;;
  "develop"|"github_actions")
    FTP_DIR="${FTP_DIR_DEV}"
      ;;
  *)
    echo "Invalid deploy branch"
    exit 1
esac

sshpass -p "${FTP_PASSWORD}" rsync -e "ssh -o StrictHostKeyChecking=no" -azrv --delete ../blog/public/ ${FTP_LOGIN}@${FTP_DOMAIN}:${FTP_DIR}
