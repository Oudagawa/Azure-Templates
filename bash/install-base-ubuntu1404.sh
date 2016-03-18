#!/bin/bash
# name:
# install-base-ubuntu1404.sh
#
# description:
# install base packages for cloud service
#
## function
log() {
  /usr/bin/logger -t powercms ${1}
}

## start
if [ $# -lt 1 ]; then
  echo "Usage: install-base.sh [username]"
  exit 1
else
  _NAME=${1}
  log "(install-base.sh) start"
fi

## configure locale
log "UPDATE locale"
/usr/sbin/locale-gen UTF-8
/usr/sbin/locale-gen en_US.UTF-8
/usr/sbin/locale-gen ja_JP.UTF-8
/bin/echo "export LC_ALL=en_US.UTF-8" >> /home/${_NAME}/.bashrc
/bin/echo "export LC_ALL=en_US.UTF-8" >> /etc/skel/.bashrc
LANG=C; export LANG

## update /etc/timezone
log "UPDATE timezone"

_FILE="/etc/timezone"
/bin/cp -a ${_FILE} ${_FILE}-original
/bin/echo "Asia/Tokyo" > ${_FILE}
/usr/sbin/dpkg-reconfigure --frontend noninteractive tzdata

## update /etc/sysctl.conf
log "UPDATE /etc/sysctl.conf"

_FILE="/etc/sysctl.conf"
_DATE=`/bin/date '+%Y%m%d_%H%M'`
/bin/cp -a ${_FILE} ${_FILE}-original
/bin/echo  >> ${_FILE}
/bin/echo "#### modified: ${_DATE}"   >> ${_FILE}
/bin/echo "## enable IPv4 forwarding" >> ${_FILE}
/bin/echo "net.ipv4.ip_forward = 1"   >> ${_FILE}
/bin/echo "## disable IPv6"           >> ${_FILE}
/bin/echo "net.ipv6.conf.all.disable_ipv6     = 1" >> ${_FILE}
/bin/echo "net.ipv6.conf.default.disable_ipv6 = 1" >> ${_FILE}
/bin/echo "net.ipv6.bindv6only                = 1" >> ${_FILE}
/bin/echo  >> ${_FILE}
/bin/echo "## supporting lsyncd"                >> ${_FILE}
/bin/echo "fs.inotify.max_user_watches = 81920" >> ${_FILE}
/sbin/sysctl -p

## update
log "update packages"
/usr/bin/aptitude -y autoclean
/usr/bin/aptitude -y update
/usr/bin/aptitude -y full-upgrade

log "add repository for PHP 5.5.x"
/usr/bin/apt-get -y install python-software-properties
/usr/bin/add-apt-repository -y ppa:ondrej/php5

## install software
_LIST=(\
  build-essential \
  cmake \
  debconf-utils \
  dstat \
  expect \
  expect-dev \
  libxml2-dev \
  libyaml-dev \
  ssmtp \
  sysstat \
  sysv-rc-conf \
  unzip \
  zip \
  imagemagick \
  libmagick++-dev \
  perlmagick \
  chrony \
  lsyncd \
  hyperestraier \
  libestraier-perl \
  supervisor \
  apache2 \
  php5 \
  php5-curl \
  php5-gd \
  php5-imagick \
  php5-mcrypt \
  php5-odbc \
  php-pear \
  libapache2-mod-php5 \
)
for _VAL in ${_LIST[@]}
do
  log "install package: ${_VAL}"
  /usr/bin/aptitude -y install ${_VAL}
done

/bin/mkdir -p /etc/lsyncd

_LIST=(\
  cgi \
  expires \
  headers \
  include \
  proxy_http \
  rewrite \
)
for _VAL in ${_LIST[@]}
do
  log "enable Apache module: ${_VAL}"
  a2enmod ${_VAL}
done

## stop service
_LIST=(\
  chrony \
  lsyncd \
  hyperestraier \
  supervisor \
  apache2 \
)
for _VAL in ${_LIST[@]}
do
  log "stop service: ${_VAL}"
  /usr/sbin/sysv-rc-conf --level 2345 ${_VAL} off
  /usr/sbin/service${_VAL} stop
done

## install software
_LIST=(\
  perlmagick \
  libarchive-zip-perl \
  libauthen-sasl-perl \
  libcache-memcached-fast-perl \
  libcache-memcached-perl \
  libcache-perl \
  libcrypt-dh-perl \
  libcrypt-dsa-perl \
  libcrypt-ssleay-perl \
  libcss-minifier-perl \
  libdbd-odbc-perl \
  libdigest-hmac-perl \
  libdigest-sha-perl \
  libgd-gd2-perl \
  libhtml-parser-perl \
  libimager-perl \
  libio-compress-perl \
  libio-socket-ssl-perl \
  libipc-run-perl \
  libjavascript-minifier-perl \
  libjson-perl \
  libmath-gmp-perl \
  libmime-tools-perl \
  libnet-cidr-perl \
  libnet-ip-perl \
  libnet-ldap-perl \
  libnet-sftp-foreign-perl \
  libnet-smtp-ssl-perl \
  libnet-smtp-tls-perl \
  libnet-ssleay-perl \
  libproc-daemon-perl \
  libproc-processtable-perl \
  libsoap-lite-perl \
  libtext-csv-perl \
  libtext-csv-xs-perl \
  libtext-simpletable-perl \
  libweb-scraper-perl \
  libxml-atom-perl \
  libxml-libxml-perl \
  libxml-parser-perl \
  libxml-sax-expat-perl \
  libxml-sax-expatxs-perl \
  libxml-sax-perl \
  libyaml-syck-perl \
)
for _VAL in ${_LIST[@]}
do
  log "install Perl modules: ${_VAL}"
  /usr/bin/aptitude -y install ${_VAL}
done

log "install Perl modules: App:cpanminus"
curl -L http://cpanmin.us | perl - --sudo App::cpanminus

_LIST=(\
  Starlet \
  # Net::Azure::StorageClient \
)
for _VAL in ${_LIST[@]}
do
  log "install Perl modules: ${_VAL}"
  /usr/local/bin/cpanm --sudo --notest ${_VAL}
done

_LIST=(\
  Devel::Leak::Object \
  Digest::SHA1 \
  Mozilla::CA \
  Net::SFTP \
  Plack::App::Proxy \
  Task::Plack \
  XMLRPC::Transport::HTTP::Plack \
)
for _VAL in ${_LIST[@]}
do
  log "install Perl modules: ${_VAL}"
  /usr/local/bin/cpanm --sudo ${_VAL}
done

## check Perl modules
_RC=`perl -MArchive::Tar -e 'print $Archive::Tar::VERSION;'`;                     log "Archive::Tar - ${_RC}"
_RC=`perl -MArchive::Zip -e 'print $Archive::Zip::VERSION;'`;                     log "Archive::Zip - ${_RC}"
_RC=`perl -MAuthen::SASL -e 'print $Authen::SASL::VERSION;'`;                     log "Authen::SASL - ${_RC}"
_RC=`perl -MCGI::PSGI -e 'print $CGI::PSGI::VERSION;'`;                           log "CGI::PSGI - ${_RC}"
_RC=`perl -MCGI::Parse::PSGI -e 'print $CGI::Parse::PSGI::VERSION;'`;             log "CGI::Parse::PSGI - ${_RC}"
_RC=`perl -MCSS::Minifier -e 'print $CSS::Minifier::VERSION;'`;                   log "CSS::Minifier - ${_RC}"
_RC=`perl -MCache::File -e 'print $Cache::File::VERSION;'`;                       log "Cache::File - ${_RC}"
_RC=`perl -MCache::Memcached -e 'print $Cache::Memcached::VERSION;'`;             log "Cache::Memcached - ${_RC}"
_RC=`perl -MCache::Memcached::Fast -e 'print $Cache::Memcached::Fast::VERSION;'`; log "Cache::Memcached::Fast - ${_RC}"
_RC=`perl -MCrypt::DSA -e 'print $Crypt::DSA::VERSION;'`;                         log "Crypt::DSA - ${_RC}"
_RC=`perl -MCrypt::SSLeay -e 'print $Crypt::SSLeay::VERSION;'`;                   log "Crypt::SSLeay - ${_RC}"
_RC=`perl -MDBD::ODBC -e 'print $DBD::ODBC::VERSION;'`;                           log "DBD::ODBC - ${_RC}"
_RC=`perl -MDevel::Leak::Object -e 'print $Devel::Leak::Object::VERSION;'`;       log "Devel::Leak::Object - ${_RC}"
_RC=`perl -MDigest::MD5 -e 'print $Digest::MD5::VERSION;'`;                       log "Digest::MD5 - ${_RC}"
_RC=`perl -MDigest::SHA -e 'print $Digest::SHA::VERSION;'`;                       log "Digest::SHA - ${_RC}"
_RC=`perl -MDigest::SHA1 -e 'print $Digest::SHA1::VERSION;'`;                     log "Digest::SHA1 - ${_RC}"
_RC=`perl -MEstraier -e 'print $Estraier::VERSION;'`;                             log "Estraier - ${_RC}"
_RC=`perl -MFile::Temp -e 'print $File::Temp::VERSION;'`;                         log "File::Temp - ${_RC}"
_RC=`perl -MGD -e 'print $GD::VERSION;'`;                                         log "GD - ${_RC}"
_RC=`perl -MHTML::Entities -e 'print $HTML::Entities::VERSION;'`;                 log "HTML::Entities - ${_RC}"
_RC=`perl -MHTML::Parser -e 'print $HTML::Parser::VERSION;'`;                     log "HTML::Parser - ${_RC}"
_RC=`perl -MIO::Compress::Gzip -e 'print $IO::Compress::Gzip::VERSION;'`;         log "IO::Compress::Gzip - ${_RC}"
_RC=`perl -MIO::Socket::SSL -e 'print $IO::Socket::SSL::VERSION;'`;               log "IO::Socket::SSL - ${_RC}"
_RC=`perl -MIO::Uncompress::Gunzip -e 'print $IO::Uncompress::Gunzip::VERSION;'`; log "IO::Uncompress::Gunzip - ${_RC}"
_RC=`perl -MIPC::Run -e 'print $IPC::Run::VERSION;'`;                             log "IPC::Run - ${_RC}"
_RC=`perl -MImage::Magick -e 'print $Image::Magick::VERSION;'`;                   log "Image::Magick - ${_RC}"
_RC=`perl -MImager -e 'print $Imager::VERSION;'`;                                 log "Imager - ${_RC}"
_RC=`perl -MJSON -e 'print $JSON::VERSION;'`;                                     log "JSON - ${_RC}"
_RC=`perl -MJavaScript::Minifier -e 'print $JavaScript::Minifier::VERSION;'`;     log "JavaScript::Minifier - ${_RC}"
_RC=`perl -MList::Util -e 'print $List::Util::VERSION;'`;                         log "List::Util - ${_RC}"
_RC=`perl -MMIME::Base64 -e 'print $MIME::Base64::VERSION;'`;                     log "MIME::Base64 - ${_RC}"
_RC=`perl -MMIME::Parser -e 'print $MIME::Parser::VERSION;'`;                     log "MIME::Parser - ${_RC}"
_RC=`perl -MMozilla::CA -e 'print $Mozilla::CA::VERSION;'`;                       log "Mozilla::CA - ${_RC}"
_RC=`perl -MNet::CIDR -e 'print $Net::CIDR::VERSION;'`;                           log "Net::CIDR - ${_RC}"
_RC=`perl -MNet::IP -e 'print $Net::IP::VERSION;'`;                               log "Net::IP - ${_RC}"
_RC=`perl -MNet::LDAP -e 'print $Net::LDAP::VERSION;'`;                           log "Net::LDAP - ${_RC}"
_RC=`perl -MNet::SFTP -e 'print $Net::SFTP::VERSION;'`;                           log "Net::SFTP - ${_RC}"
_RC=`perl -MNet::SFTP::Foreign -e 'print $Net::SFTP::Foreign::VERSION;'`;         log "Net::SFTP::Foreign - ${_RC}"
_RC=`perl -MNet::SMTP -e 'print $Net::SMTP::VERSION;'`;                           log "Net::SMTP - ${_RC}"
_RC=`perl -MNet::SMTP::SSL -e 'print $Net::SMTP::SSL::VERSION;'`;                 log "Net::SMTP::SSL - ${_RC}"
_RC=`perl -MNet::SMTP::TLS -e 'print $Net::SMTP::TLS::VERSION;'`;                 log "Net::SMTP::TLS - ${_RC}"
_RC=`perl -MNet::SSLeay -e 'print $Net::SSLeay::VERSION;'`;                       log "Net::SSLeay - ${_RC}"
_RC=`perl -MPlack -e 'print $Plack::VERSION;'`;                                   log "Plack - ${_RC}"
_RC=`perl -MProc::Daemon -e 'print $Proc::Daemon::VERSION;'`;                     log "Proc::Daemon - ${_RC}"
_RC=`perl -MProc::ProcessTable -e 'print $Proc::ProcessTable::VERSION;'`;         log "Proc::ProcessTable - ${_RC}"
_RC=`perl -MSOAP::Lite -e 'print $SOAP::Lite::VERSION;'`;                         log "SOAP::Lite - ${_RC}"
_RC=`perl -MSafe -e 'print $Safe::VERSION;'`;                                     log "Safe - ${_RC}"
_RC=`perl -MStorable -e 'print $Storable::VERSION;'`;                             log "Storable - ${_RC}"
_RC=`perl -MText::Balanced -e 'print $Text::Balanced::VERSION;'`;                 log "Text::Balanced - ${_RC}"
_RC=`perl -MText::CSV -e 'print $Text::CSV::VERSION;'`;                           log "Text::CSV - ${_RC}"
_RC=`perl -MText::CSV_XS -e 'print $Text::CSV_XS::VERSION;'`;                     log "Text::CSV_XS - ${_RC}"
_RC=`perl -MText::SimpleTable -e 'print $Text::SimpleTable::VERSION;'`;           log "Text::SimpleTable - ${_RC}"
_RC=`perl -MTime::HiRes -e 'print $Time::HiRes::VERSION;'`;                       log "Time::HiRes - ${_RC}"
_RC=`perl -MWeb::Scraper -e 'print $Web::Scraper::VERSION;'`;                     log "Web::Scraper - ${_RC}"
_RC=`perl -MXML::Atom -e 'print $XML::Atom::VERSION;'`;                           log "XML::Atom - ${_RC}"
_RC=`perl -MXML::LibXML::SAX -e 'print $XML::LibXML::SAX::VERSION;'`;             log "XML::LibXML::SAX - ${_RC}"
_RC=`perl -MXML::Parser -e 'print $XML::Parser::VERSION;'`;                       log "XML::Parser - ${_RC}"
_RC=`perl -MXML::SAX -e 'print $XML::SAX::VERSION;'`;                             log "XML::SAX - ${_RC}"
_RC=`perl -MXML::SAX::Expat -e 'print $XML::SAX::Expat::VERSION;'`;               log "XML::SAX::Expat - ${_RC}"
_RC=`perl -MXML::SAX::ExpatXS -e 'print $XML::SAX::ExpatXS::VERSION;'`;           log "XML::SAX::ExpatXS - ${_RC}"
_RC=`perl -MXMLRPC::Transport::HTTP::Plack -e 'print $XMLRPC::Transport::HTTP::Plack::VERSION;'`; log "XMLRPC::Transport::HTTP::Plack - ${_RC}"
_RC=`perl -MYAML::Syck -e 'print $YAML::Syck::VERSION;'`;                         log "YAML::Syck - ${_RC}"

## update
log "update packages"
/usr/bin/aptitude -y autoclean
/usr/bin/aptitude -y update
/usr/bin/aptitude -y full-upgrade

## end
log "(install-base.sh) end"
exit 0
