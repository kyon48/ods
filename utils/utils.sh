#!/bin/bash

cecho(){
  RED="\033[1;31m"
  GREEN="\033[0;32m"
  YELLOW="\033[0;33m"
  BLUE="\033[1;34m"
  DARKGRAY="\033[0;90m"
  NC="\033[0m"
  str="${@:2:${#@}}"
  printf "${!1}${str}  ${NC}\n"
}