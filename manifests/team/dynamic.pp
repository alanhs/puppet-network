# == Definition: network::team::dynamic
#
# Creates a teamed interface with static IP address and enables the teaming
# driver.  bootp support is unknown for teamed interfaces.  Thus no bootp
# team support in this module.
#
# === Parameters:
#
#   $ensure       - required - up|down
#   $mtu          - optional
#   $ethtool_opts - optional
#   $teaming_opts - optional
#   $zone         - optional
#   $metric       - optional
#   $defroute     - optional
#   $restart      - optional - defaults to true

#
# === Actions:
#
# Deploys the file /etc/sysconfig/network-scripts/ifcfg-$name.
# Updates /etc/modprobe.conf with teaming driver parameters.
#
# === Sample Usage:
#
#   network::team::dynamic { 'team2':
#     ensure => 'up',
#   }
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2011 Mike Arnold, unless otherwise noted.
#
define network::team::dynamic (
  $ensure,
  $mtu = undef,
  $ethtool_opts = undef,
  $teaming_opts = 'miimon=100',
  $zone = undef,
  $defroute = undef,
  $metric = undef,
  $restart = true,
) {
  # Validate our regular expressions
  $states = [ '^up$', '^down$' ]
  validate_re($ensure, $states, '$ensure must be either "up" or "down".')

  network_if_base { $title:
    ensure       => $ensure,
    ipaddress    => '',
    netmask      => '',
    gateway      => '',
    macaddress   => '',
    bootproto    => 'dhcp',
    ipv6address  => '',
    ipv6gateway  => '',
    mtu          => $mtu,
    ethtool_opts => $ethtool_opts,
    teaming_opts => $teaming_opts,
    zone         => $zone,
    defroute     => $defroute,
    metric       => $metric,
    restart      => $restart,
  }

  # Only install "alias teamN teaming" on old OSs that support
  # /etc/modprobe.conf.
  case $::operatingsystem {
    /^(RedHat|CentOS|OEL|OracleLinux|SLC|Scientific)$/: {
      case $::operatingsystemrelease {
        /^[45]/: {
          augeas { "modprobe.conf_${title}":
            context => '/files/etc/modprobe.conf',
            changes => [
              "set alias[last()+1] ${title}",
              'set alias[last()]/modulename teaming',
            ],
            onlyif  => "match alias[*][. = '${title}'] size == 0",
            before  => Network_if_base[$title],
          }
        }
        default: {}
      }
    }
    'Fedora': {
      case $::operatingsystemrelease {
        /^(1|2|3|4|5|6|7|8|9|10|11)$/: {
          augeas { "modprobe.conf_${title}":
            context => '/files/etc/modprobe.conf',
            changes => [
              "set alias[last()+1] ${title}",
              'set alias[last()]/modulename teaming',
            ],
            onlyif  => "match alias[*][. = '${title}'] size == 0",
            before  => Network_if_base[$title],
          }
        }
        default: {}
      }
    }
    default: {}
  }
} # define network::team::dynamic