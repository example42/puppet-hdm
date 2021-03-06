# @summary This class installs passenger-nginx and configures HDM
#
# A description of what this class does
#
# @example
#   include hdm::passenger::nginx
class hdm::passenger::nginx (
  Enum['present','absent'] $ensure = 'present',
  Boolean $nginx_package_manage = true,
  Boolean $passenger_package_manage = true,
  Boolean $config_manage   = true,
  String $config_template  = 'hdm/nginx/hdm.conf.epp',
  Hash $config_options     = {},
  Boolean $use_pe_nginx    = false,
) {

  if $use_pe_nginx {
    $tp_nginx_settings = {
      service_name  => 'pe-nginx',
      package_name  => 'pe-nginx',
      conf_dir_path => '/etc/puppetlabs/nginx/conf.d/',
    }
  } else {
    $tp_nginx_settings = {}
  }

  if $nginx_package_manage {
    tp::install { 'nginx':
      ensure         => $ensure,
      settings_hash  => $tp_nginx_settings,
      test_enable    => false,
      cli_enable     => false,
      tp_repo_params => {
        yum_gpgcheck => false,
      }
    }
  }
  if $passenger_package_manage {
    tp::install { 'passenger-nginx':
      ensure => $ensure,
    }
  }
  if $config_manage {
    $config_options_defaults = {
      listen => "${hdm::port} default_server",
      root => "${hdm::hdm_dir}/public",
      server_name => $hdm::servername,
      passenger_friendly_error_pages => off,
      passenger_env_vars => $::hdm::env_vars,
      extra_params => {},
    }
    $config_options_all = $config_options_defaults + $config_options

    tp::conf { 'nginx::hdm.conf':
      ensure        => $ensure,
      base_dir      => 'conf',
      content       => epp($config_template, { options => $config_options_all }),
      settings_hash => $tp_nginx_settings,
    }
  }
}
