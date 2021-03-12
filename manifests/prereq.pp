# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include hdm::prereq
class hdm::prereq (
  Enum['present','absent'] $ensure = 'present',
  Array $packages = [],
  Boolean $prereq_packages_manage = true,
  Boolean $gems_manage = true,
  Boolean $r10k_manage = true,
  Boolean $nodejs_manage = true,
  Boolean $yarn_manage = true,
) {

  if $prereq_packages_manage {
    $packages.each |$k| {
      if !defined(Package[$k]) {
        package { $k:
          ensure => $ensure,
        }
      }
    }
  }
  if $gems_manage {
    package { 'bundler':
      ensure   => $ensure,
      provider => 'puppet_gem',
    }
    exec { 'hdm bundle exec':
      command => '/opt/puppetlabs/puppet/bin/bundle install --path vendor',
      require => [Package['bundler'],Tp::Dir['hdm']],
      cwd     => $::hdm::hdm_dir,
      creates => "${::hdm::hdm_dir}/vendor/ruby",
    }
  }
  if $r10k_manage {
    package { 'r10k':
      ensure   => $ensure,
      provider => 'puppet_gem',
    }
  }
  if $nodejs_manage {
    tp::install { 'nodejs':
      ensure        => $ensure,
      upstream_repo => true,
    }
  }
  if $yarn_manage {
    tp::install { 'yarn':
      ensure => $ensure,
    }
    exec { 'hdm yarn update':
      command => '/opt/puppetlabs/puppet/bin/bundle exec yarn install --check-files',
      require => [Tp::Install['yarn'],Tp::Dir['hdm']],
      cwd     => $::hdm::hdm_dir,
      creates => "${::hdm::hdm_dir}/node_modules",
    }
  }
}
