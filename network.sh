#!/bin/bash

source $PWD/utils/utils.sh

# veriable
NET=islab
GATEWAY="172.30.1.1"
SUBNET="172.30.1.0/24"

ORDERER0_FOLDER=${PWD}/orderer0/deployfile
ORDERER1_FOLDER=${PWD}/orderer1/deployfile
ORDERER2_FOLDER=${PWD}/orderer2/deployfile
SERVICE_FOLDER=${PWD}/service/deployfile
BLOCKCHAIN_FOLDER=${PWD}/blockchain/deployfile
DAPP_FOLDER=${PWD}/dapp

#chaincode
CC_NAME=asset
CC_LANG=golang

function network_usage {
  echo "========================================================================="
  echo " network (ca, orderer) "
  echo "-------------------------------------------------------------------------"
  echo " Commands"
	echo " - build    : build artifacts for fabric network with orderer."
	echo " - rebuild    : rebuild (rm -rf build & build)"
	echo " - up   : peer node up"
	echo " - down   : docker stop & remove."
	echo " - create    : creation of the blockchain channel"
	echo " - join    : join in the blockchain channel"
	echo " - package    : package the chaincode"
	echo " - deploy    : install and commit the chaincode on channel"
	echo " - clean  	: clean artifacts"
	echo "-------------------------------------------------------------------------"
}

function func_build {
	if [ -d "$ORDERER0_FOLDER" ]; then
    pushd $ORDERER0_FOLDER
      cecho "GREEN" "  - Create to Blockchain extral network"
      docker network create --gateway $GATEWAY --subnet $SUBNET $NET

      cecho "GREEN" "  - Blockchain orderer0 node start"
      exec="docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml up -d"
      cecho "YELLOW" $exec
      $exec
    popd    
  else
    cecho "RED" "ORDERER0_FOLDER are not exist"
  fi

	if [ -d "$ORDERER1_FOLDER" ]; then
    pushd $ORDERER1_FOLDER
      cecho "GREEN" "  - Blockchain orderer1 node start"
      exec="docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml up -d"
      cecho "YELLOW" $exec
      $exec
    popd    
  else
    cecho "RED" "ORDERER1_FOLDER are not exist"
  fi

	if [ -d "$ORDERER2_FOLDER" ]; then
    pushd $ORDERER2_FOLDER
      cecho "GREEN" "  - Blockchain orderer2 node start"
      exec="docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml up -d"
      cecho "YELLOW" $exec
      $exec
    popd    
  else
    cecho "RED" "ORDERER2_FOLDER are not exist"
  fi

  cecho "GREEN" "Docker list"
  docker ps
}

function func_clean {
	docker stop $(docker ps -a -q)
  docker rm $(docker ps -a -q)
  docker rmi $(docker images dev-* -q)

  docker network prune --force
  docker container prune --force
  docker volume prune --force
}

function func_rebuild {
  func_clean
  func_build
}

function func_up {
	if [ -d "$SERVICE_FOLDER" ]; then
    pushd $SERVICE_FOLDER
      exec="./network.sh up"
      $exec
    popd
  else
    cecho "RED" "SERVICE FOLDER are not exist"
  fi

	if [ -d "$BLOCKCHAIN_FOLDER" ]; then
    pushd $BLOCKCHAIN_FOLDER
      exec="./network.sh up"
      $exec
    popd
  else
    cecho "RED" "BLOCKCHAIN FOLDER are not exist"
  fi

  cecho "GREEN" "Docker list"
  docker ps
}

function func_create {
	if [ -d "$SERVICE_FOLDER" ]; then
    pushd $SERVICE_FOLDER
      exec="./network.sh create"
      $exec
    popd
  else
    cecho "RED" "SERVICE FOLDER are not exist"
  fi
}

function func_join {
	if [ -d "$SERVICE_FOLDER" ]; then
    pushd $SERVICE_FOLDER
      exec="./network.sh join"
      $exec
    popd
  else
    cecho "RED" "SERVICE FOLDER are not exist"
  fi

	if [ -d "$BLOCKCHAIN_FOLDER" ]; then
    pushd $BLOCKCHAIN_FOLDER
      exec="./network.sh join"
      $exec
    popd
  else
    cecho "RED" "SERVICE FOLDER are not exist"
  fi
}

function func_package {
  if [ -d "$SERVICE_FOLDER" ]; then
    pushd $SERVICE_FOLDER
      exec="./network.sh packageChaincode"
      $exec
    popd
  else
    cecho "RED" "SERVICE FOLDER are not exist"
  fi

  sudo cp $SERVICE_FOLDER/${CC_NAME}.tar.gz $BLOCKCHAIN_FOLDER/${CC_NAME}.tar.gz
}

function func_only_build {
  func_rebuild
  sleep 1

  func_up
  sleep 1

  func_create
  sleep 1

  func_join
  sleep 1

  func_package
  sleep 1
}

function func_deploy {
  # install
  if [ -d "$SERVICE_FOLDER" ]; then
    pushd $SERVICE_FOLDER
      exec="./network.sh install"
      $exec
    popd
  else
    cecho "RED" "SERVICE FOLDER are not exist"
  fi

  if [ -d "$BLOCKCHAIN_FOLDER" ]; then
    pushd $BLOCKCHAIN_FOLDER
      exec="./network.sh install"
      $exec
    popd
  else
    cecho "RED" "BLOCKCHAIN FOLDER are not exist"
  fi

  # chaincodecheck
  if [ -d "$SERVICE_FOLDER" ]; then
    pushd $SERVICE_FOLDER
      exec="./network.sh chaincodecheck"
      $exec
    popd
  else
    cecho "RED" "SERVICE FOLDER are not exist"
  fi

  if [ -d "$BLOCKCHAIN_FOLDER" ]; then
    pushd $BLOCKCHAIN_FOLDER
      exec="./network.sh chaincodecheck"
      $exec
    popd
  else
    cecho "RED" "BLOCKCHAIN FOLDER are not exist"
  fi

  # deploy
  if [ -d "$SERVICE_FOLDER" ]; then
    pushd $SERVICE_FOLDER
      exec="./network.sh deploy"
      $exec
    popd
  else
    cecho "RED" "SERVICE FOLDER are not exist"
  fi
}

function func_all {
  func_only_build
  func_deploy
  func_dapp
}

function func_dapp {
	if [ -d "$DAPP_FOLDER" ]; then
    pushd $DAPP_FOLDER
      cecho "GREEN" "  - Start Dapp node start to Blockchain Network"
      exec="docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml up -d"
      cecho "YELLOW" $exec
      $exec
    popd    
  else
    cecho "RED" "DAPP_FOLDER are not exist"
  fi
}

function main {
  case $1 in
    build | rebuild | up | create | join | clean | package | chaincodeinstall | deploy | only_build | dapp | all )
      cmd=func_$1
      shift
      $cmd $@
    ;;
    *)
      network_usage
      echo "cmd does not exist"
  exit
      ;;
  esac
}

main $@
