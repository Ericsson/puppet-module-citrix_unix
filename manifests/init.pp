# == Class: citrix_unix
#
# Module to manage Citrix Presentation Server for UNIX
#
class citrix_unix (
  $ctx_patch_base_path,
  $package_adminfile,
  $package_responsefile,
  $package_source,
  $applications                     = {},
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
  $ctxssl_config_owner              = undef,
  $ctxssl_config_group              = undef,
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
  $ctxxmld_config_path              = '/var/CTXSmf/ctxxmld.cfg',
  $ctxcfg_parameters                = [],
  $ctx_patch_name                   = undef,
  $farm_name                        = undef,
  $farm_master                      = undef,
  $farm_passphrase                  = undef,
  $is_farm_master                   = false,
  $license_flexserver               = undef,
  $package_name                     = 'CTXSmf',
  $package_provider                 = 'sun',
  $package_vendor                   = 'Citrix Systems Inc',
  $package_description              = 'Citrix MetaFrame Presentation Server 4.0',
  $enable_ssl_relay                 = true,
) {

  # variable preparations
  case $ctxssl_config_owner {
    undef:   { $ctxssl_config_owner_real = $ctxssl_user_name }
    default: { $ctxssl_config_owner_real = $ctxssl_config_owner }
  }

  case $ctxssl_config_group {
    undef:   { $ctxssl_config_group_real = $ctxadm_group_name }
    default: { $ctxssl_config_group_real = $ctxssl_config_group }
  }

  if is_string($is_farm_master) {
    $is_farm_master_real = str2bool($is_farm_master)
  } else {
    $is_farm_master_real = $is_farm_master
  }

  if $farm_passphrase {
    $farm_passphrase_real = $farm_passphrase
  } else {
    $farm_passphrase_real = $farm_name
  }

  # variable validations
  validate_absolute_path(
    $ctxsrvr_user_shell,
    $ctxsrvr_user_home,
    $ctxssl_user_shell,
    $ctxssl_user_home,
    $ctxssl_config_path,
    $ctxfarm_create_response_path,
    $ctxfarm_join_response_path,
    $ctxappcfg_responsefile_base_path,
    $ctxxmld_config_path,
    $ctx_patch_base_path,
    $package_source,
    $package_responsefile,
    $package_adminfile,
    $ctxssl_config_path,
  )

  if is_string($ctxadm_group_name)            == false { fail('citrix_unix::ctxadm_group_name is not a string') }
  if is_string($ctxsrvr_user_name)            == false { fail('citrix_unix::ctxsrvr_user_name is not a string') }
  if is_string($ctxssl_user_name)             == false { fail('citrix_unix::ctxssl_user_name is not a string') }
  if is_string($ctxfarm_responsefile_owner)   == false { fail('citrix_unix::ctxfarm_responsefile_owner is not a string') }
  if is_string($ctxfarm_responsefile_group)   == false { fail('citrix_unix::ctxfarm_responsefile_group is not a string') }
  if is_string($ctxappcfg_responsefile_owner) == false { fail('citrix_unix::ctxappcfg_responsefile_owner is not a string') }
  if is_string($ctxappcfg_responsefile_group) == false { fail('citrix_unix::ctxappcfg_responsefile_group is not a string') }
  if is_string($farm_name)                    == false { fail('citrix_unix::farm_name is not a string') }
  if is_string($farm_master)                  == false { fail('citrix_unix::farm_master is not a string') }
  if is_string($license_flexserver)           == false { fail('citrix_unix::license_flexserver is not a string') }
  if is_string($package_name)                 == false { fail('citrix_unix::package_name is not a string') }
  if is_string($package_provider)             == false { fail('citrix_unix::package_provider is not a string') }
  if is_string($package_vendor)               == false { fail('citrix_unix::package_vendor is not a string') }
  if is_string($package_description)          == false { fail('citrix_unix::package_description is not a string') }
  if is_string($ctxssl_config_mode)           == false { fail('citrix_unix::ctxssl_config_mode is not a string') }
  if is_string($ctxfarm_responsefile_mode)    == false { fail('citrix_unix::ctxfarm_responsefile_mode is not a string') }
  if is_string($ctxappcfg_responsefile_mode)  == false { fail('citrix_unix::ctxappcfg_responsefile_mode is not a string') }

  validate_re($ctxssl_config_mode,          '^[0-7]{4}$', 'citrix_unix::ctxssl_config_mode is not a file mode in octal notation.')
  validate_re($ctxfarm_responsefile_mode,   '^[0-7]{4}$', 'citrix_unix::ctxfarm_responsefile_mode is not a file mode in octal notation.')
  validate_re($ctxappcfg_responsefile_mode, '^[0-7]{4}$', 'citrix_unix::ctxappcfg_responsefile_mode is not a file mode in octal notation.')

  validate_hash($applications)
  validate_array($ctxcfg_parameters)

  # functionality
  case $::osfamily {
    'Solaris': { }
    default: {
      fail("citrix_unix is supported on osfamily Solaris. Your osfamily identified as ${::osfamily}")
    }
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
    owner   => $ctxssl_config_owner_real,
    group   => $ctxssl_config_group_real,
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

  citrix_unix::ctxcfg { $ctxcfg_parameters: }

  # Citrix farm management
  if $is_farm_master_real == true {
    file { 'ctxfarm_create_responsefile':
      ensure  => file,
      path    => $ctxfarm_create_response_path,
      mode    => $ctxfarm_responsefile_mode,
      owner   => $ctxfarm_responsefile_owner,
      group   => $ctxfarm_responsefile_group,
      content => "${farm_name}\n${farm_passphrase_real}\n${farm_passphrase_real}\n",
      require => Package['ctxsmf_package'],
    }

    exec { 'ctxfarm_create':
      path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
      command => "ctxfarm -c < ${ctxfarm_create_response_path}",
      unless  => "ctxfarm -l | grep ${farm_name}",
      require => [Service['ctxsrv_service'], File['ctxfarm_create_responsefile']],
    }

    exec { 'license_config':
      path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
      command => "ctxlsdcfg -s ${license_flexserver} -p 27000 -e Platinum -c post4.0 -m FeaturePack1",
      unless  => "grep ^flexserver=${license_flexserver} ${ctxxmld_config_path}",
      require => Service['ctxsrv_service'],
    }

    create_resources('::citrix_unix::application', $applications)
  }
  else {
    file { 'ctxfarm_join_responsefile':
      ensure  => file,
      path    => $ctxfarm_join_response_path,
      mode    => $ctxfarm_responsefile_mode,
      owner   => $ctxfarm_responsefile_owner,
      group   => $ctxfarm_responsefile_group,
      content => "${farm_name}\n${farm_passphrase_real}\n${farm_master}\n",
      require => Package['ctxsmf_package'],
    }

    exec { 'ctxfarm_join':
      path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
      command => "ctxfarm -j < ${ctxfarm_join_response_path}",
      unless  => "ctxfarm -l | grep -i ${::hostname}",
      require => [Service['ctxsrv_service'], File['ctxfarm_join_responsefile']],
    }
  }
}
