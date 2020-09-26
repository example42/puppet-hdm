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
  String $config_template  = '',
  Hash $config_options     = {},

  Boolean $systemd_manage   = true,
  String $systemd_config_template  = 'hdm/systemd.epp',
  Hash $systemd_config_options     = {},

  Boolean $create_passenger_locations_fact = true,

) {

  if $passenger_package_manage {
    tp::install { 'passenger':
      ensure => $ensure,
    }
  }
  if $config_manage {
    $config_options_defaults = {
      listen => '80 default_server',
      root => "${hdm::hdm_dir}/public",
      server_name => "hdm.${facts['networking']['domain']}",
      passenger_friendly_error_pages => off,
      passenger_env_vars => {
        'HDM__CONFIG_DIR' => $::hdm::controlrepo_dir,
        'HDM__PUPPET_DB__ENABLED' => true,
        'HDM__PUPPET_DB__SELF_SIGNED_CERT' => true,
        'HDM__PUPPET_DB__TOKEN'  => $::hdm::puppetdb_token,
        'HDM__PUPPET_DB__SERVER' => "https://${::hdm::puppetdb_host}:${::hdm::puppetdb_port}",
        'PATH' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/puppet/bin',
        'RAILS_ENV' => 'production',
      },
      extra_params => {},
    }
    $config_options_all = $config_options_defaults + $config_options

    if $config_template != '' or ! $config_template {
      tp::conf { 'hdm::hdm.conf':
        ensure   => $ensure,
        base_dir => 'conf',
        content  => epp($config_template, { options => $config_options_all }),
      }
    }

  }

  if $systemd_manage {

    $systemd_config_options_defaults = {
      root => "${hdm::hdm_dir}/public",
      server_name => "hdm.${facts['networking']['domain']}",
      passenger_friendly_error_pages => off,
      passenger_env_vars => {
        'HDM__CONFIG_DIR' => $::hdm::controlrepo_dir,
        'HDM__PUPPET_DB__ENABLED' => true,
        'HDM__PUPPET_DB__SELF_SIGNED_CERT' => true,
        'HDM__PUPPET_DB__TOKEN'  => $::hdm::puppetdb_token,
        'HDM__PUPPET_DB__SERVER' => "https://${::hdm::puppetdb_host}:${::hdm::puppetdb_port}",
        'PATH' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/puppet/bin',
        'RAILS_ENV' => 'production',
      },
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
      enable => true,
      ensure => 'running',
    }
  }
}
