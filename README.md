# hdm

This module manages the installation of Hiera Data Manager (HDM) on a node.

Being HDM a Rails application, the modules optionally takes cares of all the dependencies and configurations needed to have a web server serving HDM:
- Packages prerequisites to compile
- Installation of HDM from upstream git repo on GitHub
- Deployment via r10k of a given Puppet control-repo
- HDM's gem prerequisites, via execution of bundle install
- Nodejs installation and execution of yarn install
- Passenger as Application Server, standalone or with Apache or Nginx support

Each of these corollary but necessary configurations can be skipped and managed with custom alternative classes.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with hdm](#setup)
    * [What hdm affects](#what-hdm-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with hdm](#beginning-with-hdm)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

HDM is a Web application use to discover, analyse and modify Hiera data.

It relies on an standard control-repo structure with Hiera data in Yaml files.

This modules takes care of whatever is necessary to have HDM served on a node.

In order to avoid too many other dependencies, it relies just on Tiny Puppet (tp) to install and configure all the necessary applications, like passenger, nodejs, yarn, nginx, apache...

It's always possible, via the relevant parameter called $<something>_manage, to avoid to manage in the hdm module these third party applications. It's then left to the user to configure them as needed using other modules or custom code.


## Setup

### What hdm affects

The module can manage:

* All the necessary prerequisites for packages via the default hdm::prereq class. It's possible to specify an alternative class or just to skip the incusion on any class, passing as value an empty string:

        hdm::prerequisites_class: ''

Default value is:

        hdm::prerequisites_class: hdm::prereq

* Passenger application server configured to serve the HDM rails app. The module provides (to test on different OS) profiles to use Passenger with Apache, Nginx or standalone, set via Hiera one of these or provide your own class:

        hdm::webapp_class: hdm::passenger::apache
        hdm::webapp_class: hdm::passenger::nginx
        hdm::webapp_class: hdm::passenger::standalone

* Installation of HDM app via git, using tp::dir and the vcsrepo module. By default this is enabled, with these values:

        hdm::hdm_manage: true
        hdm::hdm_git_source: 'https://github.com/example42/hdm'
        hdm::hdm_dir: /opt/hdm

* Installation via git of a control-repo configured with hdm::controlrepo_git_source to a local directory (hdm::controlrepo_dir). Use an empty value to not clone anything. r10k deploy puppetfile is then executed to retrive external modules. Default values are:

        hdm::controlrepo_manage: true
        hdm::controlrepo_git_source: 'https://github.com/example42/psick'
        hdm::controlrepo_dir: '/etc/hdm/code'

* Eventual creation of an hdm user and group. Any parameter of the user and group resources can be customized:

        hdm::user_manage = true,
        hdm::user: 'hdm'
        hdm::group: 'hdm'
        hdm::user_params: {}
        hdm::group_params: {}

### Setup Requirements

This module has the following dependencies:

* Puppet's stdlib module
* example42 tp module (with depends on example42-tinydata and puppet-vcsrepo module)

HDM needs to access to PuppetDB, either with the existing Puppet certificate (the certificate used by the hdm server must be whitelisted on PuppetDB) or with tokens to access Puppet Enteprise Console.

### Beginning with hdm

The default behaviour of the module is to (try to) install on any RedHat, Debian and SUSe derivatives, and on MacOS, a web server serving HDM using data from a local directory and a configurable PuppetDB server.

## Usage

To install and configure the full stack in order to have HDM accessible on port 8042 just inlcude the hdm class.

        include hdm


## Limitations

The module is not fully tested on the ortogonal combinations of:

* Operating Systems potentially supported: RedHat, Debian and Suse derivatives, MacOS
* Standalone installation modes: nginx, apache, standalone
* Passenger, Ruby, Rails, Nodejs versions

We expect things not to work completely for various cases.
