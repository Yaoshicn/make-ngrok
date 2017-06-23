#!/bin/bash
domain=$1
root="`pwd`/ngrok"
certificate_dir="$root/certificate"
release_dir="$root/../release"

RED='\033[0;31m'
NC='\033[0m'

if ["$1" = ""]; then 
    printf "Usage: ./make-ngrok.sh [YOUR DOMAIN]\n" 
    exit
fi

printf "Domain:${domain}\n"

printf "${RED}Git clone...${NC}\n"
git clone https://github.com/inconshreveable/ngrok && cd $root
printf "${RED}Done${NC}\n"

printf "${RED}Install go-bindata...${NC}"
go get github.com/jteeuwen/go-bindata
[ -d $root/bin ] || mkdir $root/bin && cp $GOPATH/bin/go-bindata $root/bin
printf "${RED}Done${NC}\n"

[ -d $certificate_dir ] || mkdir $certificate_dir && cd $certificate_dir

printf "${RED}Generate self-sign certificate...${NC}"
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$domain" -days 5000 -out rootCA.pem
openssl genrsa -out device.key 2048
openssl req -new -key device.key -subj "/CN=$domain" -out device.csr
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
printf "${RED}Done${NC}\n"

printf "${RED}Copy certificates and key to target folders...${NC}\n"
cd $certificate_dir
cp rootCA.pem ../assets/client/tls/ngrokroot.crt
cp device.crt ../assets/server/tls/snakeoil.crt
cp device.key ../assets/server/tls/snakeoil.key
printf "${RED}Done${NC}\n"

# make
printf "${RED}Make release server and client...${NC}\n"
cd $root
make release-server release-client
printf "${RED}Done${NC}\n"

printf "${RED}Make client for other platforms...${NC}\n"
# Linux 32
unset GOBIN && GOOS="linux" GOARCH="386" make release-client
# Linux 64
unset GOBIN && GOOS="linux" GOARCH="amd64" make release-client
# ARM
unset GOBIN && GOOS="linux" GOARCH="arm" make release-client
# Windows 32
unset GOBIN && GOOS="windows" GOARCH="386" make release-client
# Windows 64
unset GOBIN && GOOS="windows" GOARCH="amd64" make release-client
# Mac 32
unset GOBIN && GOOS="darwin" GOARCH="386" make release-client
# Mac 64
unset GOBIN && GOOS="darwin" GOARCH="amd64" make release-client
printf "${RED}Done${NC}\n"

rm -rf $release_dir
[ -d $release_dir ] || mkdir $release_dir
cp -r $root/bin/* $release_dir