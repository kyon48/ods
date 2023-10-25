#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${MSPORG}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ./ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${MSPORG}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        ./ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=service
MSPORG=service
P0PORT=7051
CAPORT=7054
PEERPEM=${PWD}/../build/channel-artifacts/crypto-config/peerOrganizations/$ORG.islab.re.kr/tlsca/tlsca.$ORG.islab.re.kr-cert.pem
CAPEM=${PWD}/../build/channel-artifacts/crypto-config/peerOrganizations/$ORG.islab.re.kr/ca/ca.$ORG.islab.re.kr-cert.pem

echo "$(json_ccp $ORG $MSPORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > ${PWD}/../build/channel-artifacts/crypto-config/peerOrganizations/$ORG.islab.re.kr/connection-$ORG.json
echo "$(yaml_ccp $ORG $MSPORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > ${PWD}/../build/channel-artifacts/crypto-config/peerOrganizations/$ORG.islab.re.kr/connection-$ORG.yaml

ORG=blockchain
MSPORG=blockchain
P0PORT=9051
CAPORT=8054
PEERPEM=${PWD}/../build/channel-artifacts/crypto-config/peerOrganizations/$ORG.islab.re.kr/tlsca/tlsca.$ORG.islab.re.kr-cert.pem
CAPEM=${PWD}/../build/channel-artifacts/crypto-config/peerOrganizations/$ORG.islab.re.kr/ca/ca.$ORG.islab.re.kr-cert.pem

echo "$(json_ccp $ORG $MSPORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > ${PWD}/../build/channel-artifacts/crypto-config/peerOrganizations/$ORG.islab.re.kr/connection-$ORG.json
echo "$(yaml_ccp $ORG $MSPORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > ${PWD}/../build/channel-artifacts/crypto-config/peerOrganizations/$ORG.islab.re.kr/connection-$ORG.yaml