# @summary This class installs Passenger standalone mode
#
# This class installs HDM in Passenger standalone mode
#
# @example
#   include hdm::passenger::standalone
class hdm::passenger::standalone (
  Enum['present','absent'] $ensure = 'present',
  Boolean $passenger_package_manage = true,

  Boolean $config_manage   = true,
  String $config_template  = 'hdm/Passengerfile.json.epp',
  Hash $config_options     = {},

  Boolean $systemd_manage   = true,
  String $systemd_config_template  = 'hdm/systemd.epp',
  Hash $systemd_config_options     = {},

  Hash $envars               = {},
) {

  if $passenger_package_manage {
    tp::install { 'passenger':
      ensure => $ensure,
    }
  }
  if $config_manage {
    $config_options_defaults = {
      port => $::hdm::port,
      environment => 'production',
      socket => '/run/passenger/hdm.sock',
      pid_file => '/run/passenger/hdm.pid',
      log_file => '/var/log/hdm/passenger.log',
      max_pool_size => 8,
      envvars =>  {
        'PATH' => '/opt/puppetlabs/puppet/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin',
      } + $::hdm::env_vars,
      extra_params => {},
    }
    $config_options_all = $config_options_defaults + $config_options

    if $config_template != '' {
      file { "${hdm::hdm_dir}/Passengerfile.json":
        ensure  => $ensure,
        content => epp($config_template, { options => $config_options_all }),
      }
    }

  }

  # Systemd
  if $systemd_manage {
    $systemd_config_options_defaults = {
      root => "${hdm::hdm_dir}/public",
      server_name => "hdm.${facts['networking']['domain']}",
      passenger_friendly_error_pages => off,
      passenger_env_vars => {
        'PATH' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/puppet/bin',
        'RAILS_ENV' => 'production',
      } + $::hdm::env_vars,
      extra_params => {},
    }
    $systemd_config_options_all = $systemd_config_options_defaults + $systemd_config_options

    file { '/etc/systemd/system/passenger-hdm.service':
      ensure  => $ensure,
      notify  => [ Exec['systemctl-daemon-reload'], Service['passenger-hdm']],
      content => epp($systemd_config_template, { options => $systemd_config_options_all }),
    }
    exec { 'systemctl-daemon-reload':
      path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      command     => 'systemctl daemon-reload',
      refreshonly => true,
      before      => Service['passenger-hdm']
    }
    service { 'passenger-hdm':
      ensure => 'running',
      enable => true,
    }
    file { '/var/log/hdm':
      ensure => directory,
      owner  => $::hdm::user,
      group  => $::hdm::group,
    }
  }
}
