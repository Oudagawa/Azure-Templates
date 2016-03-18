#!/bin/bash
# name:
# install-mysql.sh
#
# description:
# install mysql-related packages
#
## function
log() {
  /usr/bin/logger -t powercms ${1}
}

## start
if [ $# -lt 2 ]; then
  echo "Usage: install-mysql.sh [username] [password]"
  exit 1
else
  _NAME=${1}
  _PASS=${2}
  log "(install-mysql.sh) start"
fi

## update
log "update packages"
/usr/bin/aptitude -y autoclean
/usr/bin/aptitude -y update
/usr/bin/aptitude -y full-upgrade

## MySQL
_FILE="/tmp/mysql-silent-install"

echo "mysql-server-5.5 mysql-server/root_password password ${_PASS}"        > ${_FILE}
echo "mysql-server-5.5 mysql-server/root_password_again password ${_PASS}" >> ${_FILE}
cat ${_FILE} | /usr/bin/debconf-set-selections

## install software
_LIST=(\
  mysql-server \
  mysql-client \
  php5-mysql \
)
for _VAL in ${_LIST[@]}
do
  log "install package: ${_VAL}"
  /usr/bin/aptitude -y install ${_VAL}
done

/usr/bin/mysql_install_db

## stop service
_LIST=(\
  mysql \
)
for _VAL in ${_LIST[@]}
do
  log "stop service: ${_VAL}"
  /usr/sbin/sysv-rc-conf --level 2345 ${_VAL} off
  /usr/sbin/service${_VAL} stop
done

## update
log "update packages"
/usr/bin/aptitude -y autoclean
/usr/bin/aptitude -y update
/usr/bin/aptitude -y full-upgrade

## end
log "(install-mysql.sh) end"
exit 0
