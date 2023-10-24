#!/bin/bash

if [ $# -ne 1 ]
then
  echo "usage: $0 image_version"
  exit 1
fi

version=${1}

docker build -t islab-client:$version .
