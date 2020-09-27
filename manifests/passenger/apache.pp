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
      'ServerName' => $hdm::servername,
      'passenger_env_vars' => {
        'PATH' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/puppetlabs/puppet/bin',
        'RAILS_ENV' => 'production',
      } + $::hdm::env_vars,
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

