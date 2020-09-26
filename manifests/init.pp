# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hdm
class hdm (
  Optional[Variant[Sensitive,String[1]]] $puppetdb_token = undef,
  String $puppetdb_server = 'localhost',
  Integer $puppetdb_port  = 8081,

  Enum['present','absent'] $ensure = 'present',

  String $prerequisites_class = 'hdm::prereq',
  String $webapp_class = 'hdm::passenger::standalone',

  String $hdm_git_source = 'https://github.com/example42/hdm',
  Optional[String] $hdm_dir = '/opt/hdm',

  String $controlrepo_git_source = 'https://github.com/example42/psick',
  StdLib::AbsolutePath $controlrepo_dir = '/etc/hdm/code',

) {

  if $prerequisites_class != '' {
    contain $prerequisites_class
  }
  if $webapp_class != '' {
    contain $webapp_class
  }

  if $hdm_git_source != '' {
    tp::dir { 'hdm':
      ensure  => $ensure,
      path    => $hdm_dir,
      source  => $hdm_git_source,
      vcsrepo => 'git',
    }
  }

  if $controlrepo_git_source != '' {
    tp::dir { 'hdm::controlrepo':
      ensure  => $ensure,
      path    => $controlrepo_dir,
      source  => $controlrepo_git_source,
      vcsrepo => 'git',
    }
    exec { 'r10k puppetfile install hdm controlrepo':
      command => '/opt/puppetlabs/puppet/bin/r10k puppetfile install',
      cwd     => $controlrepo_dir,
      unless  => '[ $(ls modules/ | wc -l) -lt 3 ]',
    }
  }

}
