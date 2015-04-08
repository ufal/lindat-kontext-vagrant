# Setup Puppet Script
#

# =========================
#

# Global default to requiring all packages be installed & apt-update to be run first
Package {
  ensure => latest,                # requires latest version of each package to be installed
  require => Exec["apt-get-update"],
}

# Global default path settings for all 'exec' commands
Exec {
  path => "/usr/bin:/usr/sbin/:/bin:/sbin:/usr/local/bin:/usr/local/sbin",
}

# Add the 'partner' repositry to apt
# NOTE: $lsbdistcodename is a "fact" which represents the ubuntu codename (e.g. 'precise')
file { "partner.list":
  path    => "/etc/apt/sources.list.d/partner.list",
  ensure  => file,
  owner   => "root",
  group   => "root",
  content => "deb http://archive.canonical.com/ubuntu ${lsbdistcodename} partner
              deb-src http://archive.canonical.com/ubuntu ${lsbdistcodename} partner",
  notify  => Exec["apt-get-update"],
}

# Run apt-get update before installing anything
exec {"apt-get-update":
  command => "/usr/bin/apt-get update",
  refreshonly => true, # only run if notified
}

# =========================
# Basics
#

file_line { 'env_editor':
   path => '/home/vagrant/.bashrc',
   line => 'export EDITOR=vim;',
}

package { [
    'build-essential',
    'vim',
    'curl',
    'git-core',
    'unzip',
    'htop',
    'iotop',
    'links',
    'libxml-xpath-perl',
    'mc',
    'locate',
    'python-lxml',
    'python-pyicu',
    'python-docutils',
    'python-virtualenv',
    'libantlr3c-3.2-0',
    'python-mysqldb',
    'python-cheetah',
    'npm',
    'nodejs-legacy',
    'sox',
    'libsox-fmt-mp3',
    'libantlr3c-dev',
    'libpcre3-dev',
    'python2.7-dev',
    'mercurial'
  ]:
  ensure  => 'installed',
}

class { 'timezone':
  timezone => 'Europe/Prague',
}

# =========================
# db
#

class { "mysql":
  root_password => 'vagrant',
}

mysql::grant { 'lindat-kontext':
  mysql_user     => 'vagrant',
  mysql_password => 'vagrant',
}

->
class { 'phpmyadmin':
  require => [Class['mysql'], Class['php']],
}

# =========================
# monitoring
#

class { 'munin': 
    server_local    => true,
    address         => '*',
}

#
# web server
#
class { 'php':
  service       => 'apache',
  module_prefix => '',
  require       => Package['apache'],
}

php::module { 'php5-mysql': }
php::module { 'php5-cli': }
php::module { 'php5-curl': }
php::module { 'php5-gd': }
php::module { 'php5-intl': }
php::module { 'php5-mcrypt': }
php::module { 'php5-sqlite': }
php::module { 'php-apc': }

class { 'apache': 
}
apache::module { 'rewrite': 
}

#
#
file { '/etc/apache2/conf-enabled/munin.conf':
    ensure => 'present',
    source => 'file:///home/vagrant/projects/config/munin/apache.conf',
    mode   => '0664',
    require  => Package["apache"]
}

file {'/etc/apache2/sites-enabled/phpmyadmin.conf':
  ensure => link,
  target => '/etc/phpmyadmin/apache.conf',
  require  => Package["phpmyadmin"]
}
