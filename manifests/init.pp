# == Class: citrix_unix
#
# Module to manage Citrix Presentation Server for UNIX
#
class citrix_unix (
  $ctxadm_group_name                = 'ctxadm',
  $ctxadm_group_gid                 = '796',
  $ctxsrvr_user_name                = 'ctxsrvr',
  $ctxsrvr_user_uid                 = '11512',
  $ctxsrvr_user_gid                 = '796',
  $ctxsrvr_user_shell               = '/bin/tcsh',
  $ctxsrvr_user_home                = '/home/ctxsrvr',
  $ctxsrvr_user_managehome          = true,
  $ctxssl_user_name                 = 'ctxssl',
  $ctxssl_user_uid                  = '47094',
  $ctxssl_user_gid                  = '796',
  $ctxssl_user_shell                = '/bin/tcsh',
  $ctxssl_user_home                 = '/home/ctxssl',
  $ctxssl_user_managehome           = true,
  $ctxssl_config_mode               = '0640',
  $ctxssl_config_owner              = $ctxssl_user_name,
  $ctxssl_config_group              = $ctxadm_group_name,
  $ctxssl_config_path               = '/var/CTXSmf/ssl/config',
  $ctxfarm_create_response_path     = '/var/CTXSmf/ctxfarm_create.response',
  $ctxfarm_join_response_path       = '/var/CTXSmf/ctxfarm_join.response',
  $ctxfarm_responsefile_mode        = '0640',
  $ctxfarm_responsefile_owner       = 'root',
  $ctxfarm_responsefile_group       = 'root',
  $ctxappcfg_responsefile_base_path = '/var/CTXSmf',
  $ctxappcfg_responsefile_mode      = '0640',
  $ctxappcfg_responsefile_owner     = 'root',
  $ctxappcfg_responsefile_group     = 'root',
  $package_name                     = 'CTXSmf',
  $package_provider                 = 'sun',
  $package_source                   = undef,
  $package_vendor                   = 'Citrix Systems Inc',
  $package_description              = 'Citrix MetaFrame Presentation Server 4.0',
  $package_responsefile             = undef,
  $package_adminfile                = undef,
  $ctx_patch_name                   = undef,
  $ctx_patch_base_path              = undef,
  $ctxcfg_parameters                = undef,
  $enable_ssl_relay                 = true,
) {

  case $::osfamily {
    'Solaris': { }
    default: {
      fail("citrix_unix is supported on osfamily Solaris. Your osfamily identified as ${::osfamily}")
    }
  }

  if $ctx_patch_base_path {
    validate_absolute_path($ctx_patch_base_path)
  } else {
    fail('ctx_patch_base_path must be set to a absolute path containing the Citrix patch')
  }

  if $package_source {
    validate_absolute_path($package_source)
  } else {
    fail('package_source must be set')
  }

  if $package_responsefile {
    validate_absolute_path($package_responsefile)
  } else {
    fail('package_responsefile must be set')
  }

  if $package_adminfile {
    validate_absolute_path($package_adminfile)
  } else {
    fail('package_adminfile must be set')
  }

  if $ctxssl_config_path {
    validate_absolute_path($ctxssl_config_path)
  } else {
    fail('ctxssl_config_path must be set')
  }

  if $ctxcfg_parameters {
    validate_array($ctxcfg_parameters)
  }

  group { 'ctxadm_group':
    ensure => present,
    name   => $ctxadm_group_name,
    gid    => $ctxadm_group_gid,
  }

  user { 'ctxsrvr_user':
    ensure     => present,
    name       => $ctxsrvr_user_name,
    uid        => $ctxsrvr_user_uid,
    gid        => $ctxsrvr_user_gid,
    comment    => 'Citrix System User',
    home       => $ctxsrvr_user_home,
    shell      => $ctxsrvr_user_shell,
    managehome => $ctxsrvr_user_managehome,
    require    => Group['ctxadm_group'],
  }

  user { 'ctxssl_user':
    ensure     => present,
    name       => $ctxssl_user_name,
    uid        => $ctxssl_user_uid,
    gid        => $ctxssl_user_gid,
    comment    => 'Citrix SSL User',
    home       => $ctxssl_user_home,
    shell      => $ctxssl_user_shell,
    managehome => $ctxssl_user_managehome,
    require    => Group['ctxadm_group'],
  }

  package { 'ctxsmf_package':
    ensure       => installed,
    name         => $package_name,
    description  => $package_description,
    provider     => $package_provider,
    vendor       => $package_vendor,
    source       => $package_source,
    responsefile => $package_responsefile,
    adminfile    => $package_adminfile,
    require      => User['ctxsrvr_user','ctxssl_user'],
    notify       => Exec['ctxpatch'],
  }

  exec { 'ctxpatch':
    path        => '/bin:/usr/bin:/usr/local/bin:/usr/sbin',
    cwd         => $ctx_patch_base_path,
    command     => "patchadd -M . ${ctx_patch_name}",
    timeout     => 60,
    refreshonly => true,
    require     => Package['ctxsmf_package'],
  }

  file { 'ctx_ssl_config':
    ensure  => file,
    path    => $ctxssl_config_path,
    mode    => $ctxssl_config_mode,
    owner   => $ctxssl_config_owner,
    group   => $ctxssl_config_group,
    content => template('citrix_unix/ssl_config.erb'),
    require => Package['ctxsmf_package'],
    notify  => Service['ctxsrv_service'],
  }

  service { 'ctxsrv_service':
    ensure   => running,
    name     => 'ctxsrv',
    enable   => false, # correct?
    pattern  => '/opt/CTXSmf/slib/ctxfm',
    provider => base,
    start    => '/opt/CTXSmf/sbin/ctxsrv start all',
    require  => Package['ctxsmf_package'],
  }

  if $ctxcfg_parameters {
    citrix_unix::ctxcfg { $ctxcfg_parameters: }
  }
}
