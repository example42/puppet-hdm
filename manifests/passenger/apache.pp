# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hdm::passenger::apache
class hdm::passenger::apache (
  Enum['present','absent'] $ensure = 'present',
  Boolean $apache_package_manage = true,
  Boolean $passenger_package_manage = true,
  Boolean $config_manage   = true,
  String $config_template  = 'hdm/apache/hdm.conf.epp',
  Hash $config_options     = {},
  Integer $port            = 8042,
) {

  if $apache_package_manage {
    tp::install { 'apache':
      ensure      => $ensure,
      test_enable => false,
      cli_enable  => false,
    }
  }
  if $passenger_package_manage {
    tp::install { 'passenger-apache':
      ensure => $ensure,
    }
  }
  if $config_manage {
    $config_options_defaults = {
      'DocumentRoot' => "${::hdm::hdm_dir}/public",
      'PassengerAppRoot' => $::hdm::hdm_dir,
      'ServerName' => "hdm.${facts['networking']['domain']}",
      'passenger_env_vars' => {
        'HDM__CONFIG_DIR' => '/etc/puppetlabs/code/environments',
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

    tp::conf { 'apache::hdm.conf':
      ensure   => $ensure,
      base_dir => 'conf',
      content  => epp($config_template, { options => $config_options_all }),
    }
  }
}

