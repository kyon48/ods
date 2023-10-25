# 0. 실행환경

Apple M1 Ultra
128GB memory
Ventura 13.1

| 구분           | 버전    |
| -------------- | ------- |
| docker         | 24.0.6  |
| docker-compose | 2.21.0  |
| go             | 1.21.1  |
| node           | 18.18.0 |
| npm            | 9.8.1   |

Fabric newtork version : 2.2  
chaincode : asset (default, fabric-samples)  
chaincode language : golang

# 1. 폴더 설명

| 구분       | 설명                                                  |
| ---------- | ----------------------------------------------------- |
| backup     | 네트워크에 필요한 config, crypto 파일들을 생성, 전달  |
| blockchain | 블록체인 네트워크 구성 조직 1, 피어 1                 |
| service    | 블록체인 네트워크 구성 조직 2, 피어 1                 |
| orderer0   | 블록체인 네트워크 오더러 0                            |
| orderer1   | 블록체인 네트워크 오더러 1                            |
| orderer2   | 블록체인 네트워크 오더러 2                            |
| dapp       | 블록체인 네트워크에 요청/응답 받을 수 있는 클라이언트 |
| utils      | echo 설정 파일                                        |

# 2. git clone

```bash
git clone https://github.com/islab-bc/backup-fabric.git
```

# 3. docker image 만들기

dapp 이미지 만들기

```bash
cd backup-fabric/dapp
./islab-client.sh 0.1
```

couchdb-amd64 이미지 만들기

```bash
cd ../couchdb-amd64
./islab-couchdb.sh 0.1
```

# 4. config, channel, crypto 파일 만들기

```bash
cd backup-fabric
./network.sh backup
```

# 5. docker 이미지 파일 확인하기

현재 버전은 M1에서 진행했기 때문에, 이외의 환경에서는 알맞은 docker image 설정해줘야함

1. service, blockchain, orderer0, orderer1, orderer2 폴더 내 docker-compose.yaml 파일 내 이미지 파일 확인
2. ~/backup-fabric/backup/backup.sh 파일 내에서 사용하는 fabric-tools 이미지 파일 확인
3. ~/backup-fabric/network.sh 파일 내에서 사용하는 fabric-tools 이미지 파일 확인

| 구분    | 이미지 파일                          | 확인 필요 여부 |
| ------- | ------------------------------------ | -------------- |
| peer    | hyperledger/fabric-peer:amd64-2.2    | \*             |
| orderer | hyperledger/fabric-orderer:amd64-2.2 | \*             |
| cli     | hyperledger/fabric-tools:amd64-2.2   | \*             |
| ca      | hyperledger/fabric-ca:amd64-1.5.5    | \*             |
| couchdb | couchdb-amd64:0.1                    | \*             |
| dapp    | node:18.18.0                         | \-             |

# 6. 한번에 실행하기

네트워크 빌드, 체인코드 설치, Dapp을 한번에 띄움

```bash
./network.sh all
```

## 6-1. 네트워크 노드 띄우기 & 채널 접속

```bash
./network.sh only_build
```

## 6-2. 체인코드 설치

```bash
./network.sh deploy
```

## 6-3. dapp 실행

```bash
./network.sh dapp
```

# 7. Dapp 사용하기 (swagger)

http://localhost:4000/api-docs 접속

1. Admin 등록 /user/enrollAdmin (admin/adminpw)
2. User 등록 /user/enroll (user0/1234)

# 8. 네트워크 내리기

```bash
./network clean
```

# 9. [주의] 다시 실행할 때

네트워크를 다시 시작할때는, backup을 다시 할 필요가 없게 만들어둠  
패브릭 네트워크를 시작하기 전에, bakcup을 한번 실행했다면  
그 다음부터는 backup 명령어를 반드시 다시 시작할 필요 없음

특히, dapp을 사용하기 위해 admin과 user를 등록했다면  
backup을 실행하면  
다시 등록해야하기 때문에 번거로움

네트워크를 내리고 다시 시작하고 싶다면,
all 명령어를 사용하거나,  
clean 명령후 사용후, only_build, deploy, dapp 순으로 실행하면됨
