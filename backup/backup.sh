#!/bin/bash

source $PWD/../utils/utils.sh

export BDIR=$PWD/build
export BCDIR=$BDIR/channel-artifacts
export CCDIR=$BCDIR/crypto-config
export CADIR=$CCDIR/fabric-ca-server
export SBDIR=$BCDIR/system-genesis-block
export CHDIR=$BCDIR/channel

export CCPDIR=$PWD/ccp
export FFDIR=$PWD/config
export FTDIR=$PWD/configtx
export GENDIR=$PWD/cryptogen

CLI_TAG_VERSION=2.2

CHANNEL_NAME=servicechannel

CLI_WORK_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/build

NODE=(service blockchain orderer0 orderer1 orderer2)
ORGS=(service blockchain)

# channel with cryptof
function func_generate_crypto {
  cecho "GREEN" "  - Generate crypto files for the blockchain network"
  mkdir -p $BCDIR

  sudo cp $GENDIR/crypto-config.yaml $BCDIR/crypto-config.yaml
	
	exec="docker run --rm --name fabric-tools \
          -v $BDIR/:$CLI_WORK_PATH \
          -w $CLI_WORK_PATH \
          hyperledger/fabric-tools:${CLI_TAG_VERSION} cryptogen generate --config=$CLI_WORK_PATH/channel-artifacts/crypto-config.yaml --output=$CLI_WORK_PATH/channel-artifacts/crypto-config"
  cecho "YELLOW" $exec
  $exec
}

function func_generate_artifacts {
  if [ ! -d "$SBDIR" ]; then
    mkdir -p $SBDIR
  else
    sudo rm -rf $SBDIR
    mkdir -p $SBDIR
  fi
  sudo cp $FTDIR/configtx.yaml $BCDIR/configtx.yaml

  cecho "GREEN" "  - Generate crypto genesis block for the blockchain network"
  exec="docker run --rm --name fabric-tools \
    -e FABRIC_CFG_PATH=$CLI_WORK_PATH/channel-artifacts \
    -v $BDIR:$CLI_WORK_PATH \
    -w $CLI_WORK_PATH \
    hyperledger/fabric-tools:$CLI_TAG_VERSION \
    configtxgen -profile systemChannel -channelID system-channel -outputBlock $CLI_WORK_PATH/channel-artifacts/system-genesis-block/genesis.block"
  cecho "YELLOW" $exec
  $exec

  cecho "GREEN" "  - Generate crypto channel file(tx) for the blockchain network"
	mkdir -p $CHDIR
  exec="docker run --rm --name fabric-tools \
    -e FABRIC_CFG_PATH=$CLI_WORK_PATH/channel-artifacts \
    -v $BDIR:$CLI_WORK_PATH \
    -w $CLI_WORK_PATH \
    hyperledger/fabric-tools:$CLI_TAG_VERSION \
    configtxgen -profile $CHANNEL_NAME -outputCreateChannelTx $CLI_WORK_PATH/channel-artifacts/channel/$CHANNEL_NAME.tx -channelID $CHANNEL_NAME"
  cecho "YELLOW" $exec
  $exec
}


function func_generate_ccp {
  cecho "GREEN" "  - Generate connection profile for the blockchain network"
  # if [ -e "${CCPDIR}/ccp-generate.sh" ]; then
  #   docker exec -i -t \
  #     cli_service /bin/bash \
  #       -c "pushd \"${CLI_CHAINCODE_PATH}/ccp/\" && ./ccp-generate.sh && popd"
  # else
  #   cecho "RED" "ccp-generate.sh is not exist"
  # fi
  sudo cp $CCPDIR/connection-service.json ${PWD}/build/channel-artifacts/crypto-config/peerOrganizations/service.islab.re.kr/connection-service.json
  sudo cp $CCPDIR/connection-blockchain.json ${PWD}/build/channel-artifacts/crypto-config/peerOrganizations/blockchain.islab.re.kr/connection-blockchain.json
}

function func_copy {
  cecho "GREEN" "  - Copy the channel artifacts"
  for o in ${NODE[@]}
  do
    # copy crypto-config
    if [ ! -d $PWD/../$o/deployfile/crypto-config ]; then
      mkdir $PWD/../$o/deployfile/crypto-config
    else
      sudo rm -rf $PWD/../$o/deployfile/crypto-config
      mkdir $PWD/../$o/deployfile/crypto-config
    fi
    sudo cp -r $PWD/build/channel-artifacts/crypto-config/* $PWD/../$o/deployfile/crypto-config/

    # copy genesis block
    if [ ! -d $PWD/../$o/deployfile/block ]; then
      mkdir $PWD/../$o/deployfile/block
    else
      sudo rm -rf $PWD/../$o/deployfile/block
      mkdir $PWD/../$o/deployfile/block
    fi
    sudo cp -r $PWD/build/channel-artifacts/system-genesis-block/genesis.block $PWD/../$o/deployfile/block/genesis.block

    # copy block
    if [ ! -d $PWD/../$o/deployfile/channel-block ]; then
      mkdir $PWD/../$o/deployfile/channel-block
    else
      sudo rm -rf $PWD/../$o/deployfile/channel-block
      mkdir $PWD/../$o/deployfile/channel-block
    fi
    sudo cp -r $PWD/build/channel-artifacts/channel/* $PWD/../$o/deployfile/channel-block/
  done

  if [ ! -d $PWD/../dapp/crypto-config ]; then
    mkdir $PWD/../dapp/crypto-config
  else
    sudo rm -rf $PWD/../dapp/crypto-config
    mkdir $PWD/../dapp/crypto-config
  fi
  sudo cp -r $PWD/build/channel-artifacts/crypto-config/* $PWD/../dapp/crypto-config/

  if [ ! -d $PWD/../dapp/wallet ]; then
    mkdir $PWD/../dapp/wallet
  else
    sudo rm -rf $PWD/../dapp/wallet
    mkdir $PWD/../dapp/wallet
  fi
}

## chaincode
function func_clean_chaincode {
  for o in ${NODE[@]}
  do
    sudo rm -rf $PWD/../$o/deployfile/*.tar.gz
  done
}

function func_chaincode {
  cc=$1
  l=$2

  cecho "GREEN" "  - install chaincode package"
  if [ "$l" == "node" ]; then
    exec="docker run --rm  --name fabric-tools \
      -e FABRIC_CFG_PATH=$CLI_WORK_PATH \
      -v $PWD/chaincode/${cc}:$CLI_WORK_PATH \
      -w $CLI_WORK_PATH \
      hyperledger/fabric-tools:$CLI_TAG_VERSION \
      npm install"
      # pushd ${CLI_WORK_PATH}/${cc} \&\& npm install \&\& npm run build"
    cecho "YELLOW" $exec
    $exec
  elif [ "$l" == "golang" ]; then
    exec="docker run --rm  --name fabric-tools \
      -e FABRIC_CFG_PATH=$CLI_WORK_PATH \
      -v $PWD/chaincode/${cc}:$CLI_WORK_PATH \
      -w $CLI_WORK_PATH \
      hyperledger/fabric-tools:$CLI_TAG_VERSION \
      go mod vendor"
    cecho "YELLOW" $exec
    $exec
  else
    cecho "RED" "Not support language for chaincode"
  fi
}

function func_copy_chaincode {
  cc=$1

  for o in ${NODE[@]}
  do
    # copy crypto-config
    if [ ! -d $PWD/../$o/deployfile/chaincode ]; then
      mkdir $PWD/../$o/deployfile/chaincode
    else
      sudo rm -rf $PWD/../$o/deployfile/chaincode
      mkdir $PWD/../$o/deployfile/chaincode
    fi
    sudo cp -r $PWD/chaincode/${cc} $PWD/../$o/deployfile/chaincode/${cc}
  done
}

# all & clean
function func_all {
  func_clean
  func_generate_crypto
  func_generate_artifacts
  func_generate_ccp
}

function func_clean {
  sudo rm -rf $BDIR
}

function main {
  case $1 in
    crypto | artifacts | copy | all | clean | chaincode | copy_chaincode | clean_chaincode )
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
