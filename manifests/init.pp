# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hdm
class hdm (
  Optional[String[1]] $puppetdb_token_path = '~/.puppetlabs/token',

  Optional[Variant[Sensitive,String[1]]] $puppetdb_token = undef,

  String $servername = $facts['networking']['fqdn'],
  Integer $port      = 8042,

  Hash $extra_env_vars    = {},

  String $puppetdb_server = "puppet.${facts['networking']['domain']}",
  Integer $puppetdb_port  = 8081,

  Enum['present','absent'] $ensure = 'present',

  String $prerequisites_class = 'hdm::prereq',
  String $webapp_class = 'hdm::passenger::nginx',

  Boolean $hdm_manage = true,
  String $hdm_git_source = 'https://github.com/example42/hdm',
  Optional[String] $hdm_dir = '/opt/hdm',

  Boolean $controlrepo_manage = true,
  String $controlrepo_git_source = 'https://github.com/example42/psick',
  StdLib::AbsolutePath $controlrepo_dir = '/etc/hdm/code',

  Boolean $user_manage = true,
  String $user         = 'hdm',
  String $group        = 'hdm',
  Hash $user_params    = {},
  Hash $group_params   = {},

) {

  # Setting $hdm::env_vars
  $default_env_vars = {
    'HDM__CONFIG_DIR' => $::hdm::controlrepo_dir,
    'HDM__PUPPET_DB__ENABLED' => true,
    'HDM__PUPPET_DB__SELF_SIGNED_CERT' => true,
    'HDM__PUPPET_DB__TOKEN'  => $::hdm::puppetdb_token,
    'HDM__PUPPET_DB__SERVER' => "https://${::hdm::puppetdb_server}:${::hdm::puppetdb_port}",
  }
  $env_vars = $default_env_vars + $extra_env_vars

  # Prerequisites
  if $prerequisites_class != '' {
    contain $prerequisites_class
  }

  # HDM Web Application server
  if $webapp_class != '' {
    contain $webapp_class
  }

  # HDM code
  if $hdm_git_source != '' and $hdm_manage {
    tp::dir { 'hdm':
      ensure  => $ensure,
      path    => $hdm_dir,
      source  => $hdm_git_source,
      vcsrepo => 'git',
    }
  }

  # Control repo deployment
  if $controlrepo_git_source != '' and $controlrepo_manage {
    tp::dir { 'hdm::controlrepo':
      ensure  => $ensure,
      path    => $controlrepo_dir,
      source  => $controlrepo_git_source,
      vcsrepo => 'git',
    }
    exec { 'r10k puppetfile install hdm controlrepo':
      command => '/opt/puppetlabs/puppet/bin/r10k puppetfile install',
      cwd     => $controlrepo_dir,
      onlyif  => '[ $(ls modules/ | wc -l) -lt 3 ]',
    }
  }

  # Dedicated hdm user
  if $user_manage {
    user { $user:
      ensure => $ensure,
      *      => $user_params,
    }
    group { $group:
      ensure => $ensure,
      *      => $group_params,
    }
  }
}
