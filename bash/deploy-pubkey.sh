#!/bin/bash
# name:
# deploy-pubkey.sh
#
# description:
# deploy public key to specified host
#
## usage
if [ $# -lt 1 ]; then
  echo "Usage: deploy-pub.sh <name of host>"
  exit 1
fi

## variables
_USER="pcmsadmn"
_HOST=${1}

## start
echo "==== update ./.ssh/authorized_keys"
ssh ${_USER}@${_HOST} "\
echo \"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBlZioI37G+6e3eKf57Mc5qTlCrl1wJFabgrSX74mSpYWRSwVJ/bEjkOgKQjZdTSGTy4SZ0RhmhsokVSRfFCMjMgmF0PjrngcIIeVClPh1suyEJ2ohullkw+Db0JcAwv+vJOTdntznXJvAlH1ElhoZz96qI07xprqVkS6OtGMKXGsUBqMuT4jqCuXFXrUWLltHoADWGVnNXVyutmUFjC5AHVAkK8cbeviiQdaI+Y05mYcJPo160AXMrWZdlIopzrIhoZ6izfTdvJtdbC9oqgTD5r9NnH7X76z7j3QfLFWDi8zj/1pOhC2e0yB/rUm+5g1Apf0k2if449p0V6x1M9Dp\" > ~/.ssh/authorized_keys; \
chmod 600 ~/.ssh/authorized_keys;"

## end
exit 0
