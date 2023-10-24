#!/bin/bash

source $PWD/../../utils/utils.sh

CCDIR=${PWD}/chaincode

# consortium org
CONSOR=service
CONSOR_POLICY="OR('serviceMSP.member','blockchainMSP.member')"

# default variable
ORG=blockchain
PEERS=(peer0)
CHANNEL_NAMES=servicechannel

# chaincode
CC_NAME=asset
CC_LANG=golang
CC_VERS="1.0"

function set_other_org {
  ORG=$1

  case $1 in
    blockchain ) 
      PEER_PORT=9051 ;;
    service ) 
      PEER_PORT=7051 ;;
    *)
      echo "org does not exist"
  esac

  CLI=cli.peer0.${ORG}.islab.re.kr
  ORDERER=orderer0.islab.re.kr:7050
  LOCALMSP=${ORG}MSP
  ADDRESS="peer0.${ORG}.islab.re.kr:${PEER_PORT}"
  CA_CERT=crypto-config/ordererOrganizations/islab.re.kr/tlsca/tlsca.islab.re.kr-cert.pem
  PEER_KEY=crypto-config/peerOrganizations/${ORG}.islab.re.kr/users/Admin@${ORG}.islab.re.kr/tls/client.key 
  PEER_CERT=crypto-config/peerOrganizations/${ORG}.islab.re.kr/users/Admin@${ORG}.islab.re.kr/tls/client.crt
  TLS_PEER_CERT=crypto-config/peerOrganizations/${ORG}.islab.re.kr/peers/peer0.${ORG}.islab.re.kr/tls/ca.crt

  HEADER="docker exec -it \
          -e CORE_PEER_LOCALMSPID=${ORG}MSP \
          -e CORE_PEER_MSPCONFIGPATH=crypto-config/peerOrganizations/${ORG}.islab.re.kr/users/Admin@${ORG}.islab.re.kr/msp \
          -e CORE_PEER_TLS_CLIENTCERT_FILE=crypto-config/peerOrganizations/${ORG}.islab.re.kr/users/Admin@${ORG}.islab.re.kr/tls/client.crt \
          -e CORE_PEER_TLS_CLIENTKEY_FILE=crypto-config/peerOrganizations/${ORG}.islab.re.kr/users/Admin@${ORG}.islab.re.kr/tls/client.key \
          -e CORE_PEER_TLS_CLIENTROOTCA_FILE=crypto-config/peerOrganizations/${ORG}.islab.re.kr/users/Admin@${ORG}.islab.re.kr/tls/ca.crt \
          -e CORE_PEER_TLS_CERT_FILE=crypto-crypto-config/peerOrganizations/${ORG}.islab.re.kr/peers/peer0.${ORG}.islab.re.kr/tls/server.crt \
          -e CORE_PEER_TLS_KEY_FILE=crypto-config/peerOrganizations/${ORG}.islab.re.kr/peers/peer0.${ORG}.islab.re.kr/tls/server.key \
          -e CORE_PEER_TLS_ROOTCERT_FILE=crypto-config/peerOrganizations/${ORG}.islab.re.kr/peers/peer0.${ORG}.islab.re.kr/tls/ca.crt \
          -e CORE_PEER_ADDRESS=peer0.${ORG}.islab.re.kr:$PEER_PORT"
}

# build docker container
function func_up {
  cecho "GREEN" "  - Blockchain nodes start"
  exec="docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml up -d"
  cecho "YELLOW" $exec
  $exec
}

## channel
function func_create {  
  cecho "GREEN" "  - Create Channel $CHANNEL_NAMES"
  set_other_org $ORG
  exec="$HEADER $CLI peer channel create \
    -o $ORDERER \
    -c $CHANNEL_NAMES \
    -f channel-block/$CHANNEL_NAMES.tx \
    --outputBlock channel-block/$CHANNEL_NAMES.block \
    --tls --cafile $CA_CERT --clientauth --keyfile $PEER_KEY --certfile $PEER_CERT"
  cecho "YELLOW" $exec
  $exec

  sudo cp $PWD/channel-block/$CHANNEL_NAMES.block $PWD/../../$CONSOR/deployfile/channel-block/$CHANNEL_NAMES.block
}

function func_join {    
  set_other_org $ORG
  cecho "GREEN" "     [CHANNEL JOIN] peer0.${ORG}.islab.re.kr - $CHANNEL_NAMES"
  cmd="$HEADER $CLI peer channel join -b channel-block/$CHANNEL_NAMES.block"        
  echo $cmd
  $cmd 
}

## chaincode
function func_packageChaincode {
  cecho "GREEN" "  - package chaincde"
  set_other_org $ORG
  exec="$HEADER $CLI peer lifecycle chaincode package ${CC_NAME}.tar.gz --path chaincode/${CC_NAME} --lang $CC_LANG --label ${CC_NAME}_${CC_VERS}"
  cecho "YELLOW" $exec
  $exec
}

function func_install {
  set_other_org $ORG
  cecho "GREEN" "  - install chaincode to peer"
  exec="$HEADER $CLI peer lifecycle chaincode install ${CC_NAME}.tar.gz"
  cecho "YELLOW" $exec
  $exec
}

function func_query_install {
  set_other_org $ORG
  cecho "GREEN" "  - query chaincode to peer"
  exec="$HEADER $CLI peer lifecycle chaincode queryinstalled"
  cecho "YELLOW" $exec
  $exec >&log.txt
}

function func_approve_for_org {
  set_other_org $ORG
  array_id=(`cat $PWD/log.txt`)
  PRE_PACKAGE_ID=${array_id[6]}
  PACKAGE_ID=${PRE_PACKAGE_ID:0:${#PRE_PACKAGE_ID}-1}
  # PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERS}/{s/^Package ID: //; s/, Label:.*$//; p;}" $PWD/log.txt)
  cecho "GRAY" "  - PACKAGE ID: ${PACKAGE_ID}"

  cecho "GREEN" "  - approve chaincode for organization"
  exec="$HEADER $CLI peer lifecycle chaincode approveformyorg \
    -o $ORDERER \
    --tls --cafile "$CA_CERT" \
    --channelID $CHANNEL_NAMES \
    --name $CC_NAME \
    --package-id $PACKAGE_ID \
    --version $CC_VERS \
    --sequence 1 \
    --waitForEvent"
  cecho "YELLOW" $exec
  $exec  
}

function func_check_commit_readiness {
  set_other_org $ORG
  cecho "GREEN" "  - check commit readiness for organization"
  exec="$HEADER $CLI peer lifecycle chaincode checkcommitreadiness \
    --channelID $CHANNEL_NAMES \
    --name $CC_NAME \
    --version $CC_VERS \
    --sequence 1 \
    --output json --init-required"
  cecho "YELLOW" $exec
  $exec
}

function set_parse_peer_connection_parameters {
  PEER_CONN_PARAMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    set_other_org $1
    PEER="peer0.${ORG}"
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $ADDRESS"
    TLSINFO=$(eval echo "--tlsRootCertFiles $TLS_PEER_CERT")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    shift
  done
  cecho "GRAY" $PEERS
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
  cecho "GRAY" $PEERS
}

function func_commit {
  set_other_org $ORG
  cecho "GREEN" "  - commit chaincode"
  exec="$HEADER $CLI peer lifecycle chaincode commit \
      -o $ORDERER \
      --tls --cafile $CA_CERT \
    --channelID $CHANNEL_NAMES \
    --name $CC_NAME \
    --version $CC_VERS \
    --sequence 1 "
  cecho "YELLOW" $exec
  $exec
}

function func_query_committed {
  set_other_org $ORG
  cecho "GREEN" "  - query committed"
  exec="$HEADER $CLI peer lifecycle chaincode querycommitted \
    --channelID $CHANNEL_NAMES \
    --name $CC_NAME"
  cecho "YELLOW" $exec
  $exec
}

function func_chaincodecheck {
  func_query_install
  sleep 1

  func_approve_for_org
  sleep 1

  func_check_commit_readiness
  sleep 1
}

function func_deploy {
  func_commit
  sleep 1

  func_query_committed
  sleep 1
}

function main {
  case $1 in
    up | create | join | packageChaincode | install | chaincodecheck | deploy )
      cmd=func_$1
      shift
      $cmd $@
    ;;
    *)
      echo "cmd does not exist"
  exit
      ;;
  esac
}

main $@
