# == Class: citrix_unix::farm
#
class citrix_unix::farm (
  $is_master    = false,
  $farm_name    = undef,
  $master       = undef,
  $passphrase   = undef,
  $applications = undef,
) inherits citrix_unix {

  validate_string($farm_name)

  if $applications {
    validate_hash($applications)
  }

  if is_string($is_master) {
    $is_master_real = str2bool($is_master)
  } else {
    $is_master_real = $is_master
  }

  if $passphrase {
    $passphrase_real = $passphrase
  } else {
    $passphrase_real = $farm_name
  }

  if $is_master_real == true {
    file { 'ctxfarm_create_responsefile':
      ensure  => file,
      path    => $citrix_unix::ctxfarm_create_response_path,
      mode    => $citrix_unix::ctxfarm_responsefile_mode,
      owner   => $citrix_unix::ctxfarm_responsefile_owner,
      group   => $citrix_unix::ctxfarm_responsefile_group,
      content => "${farm_name}\n${passphrase_real}\n${passphrase_real}\n",
    }

    exec { 'ctxfarm_create':
      path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
      command => "ctxfarm -c < ${citrix_unix::ctxfarm_create_response_path}",
      unless  => "ctxfarm -l | grep ${farm_name}",
      require => [Service['ctxsrv_service'], File['ctxfarm_create_responsefile']],
    }

    exec { 'license_config':
      path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
      command => "ctxlsdcfg -s ${citrix_unix::license_flexserver} -p 27000 ctxlsdcfg -e Platinum ctxlsdcfg -c post4.0 ctxlsdcfg -m FeaturePack1",
      unless  => "grep ^flexserver=${citrix_unix::license_flexserver} ${ctxxmld_config_path}",
      require => Service['ctxsrv_service'],
    }

    if $applications {
      create_resources('citrix_unix::application', $applications)
    }
  }
  else {
    validate_string($master)

    file { 'ctxfarm_join_responsefile':
      ensure  => file,
      path    => $citrix_unix::ctxfarm_join_response_path,
      mode    => $citrix_unix::ctxfarm_responsefile_mode,
      owner   => $citrix_unix::ctxfarm_responsefile_owner,
      group   => $citrix_unix::ctxfarm_responsefile_group,
      content => "${farm_name}\n${passphrase_real}\n${master}\n",
    }

    exec { 'ctxfarm_join':
      path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
      command => "ctxfarm -j < ${citrix_unix::ctxfarm_join_response_path}",
      unless  => "ctxfarm -l | grep -i ${::hostname}",
      require => [Service['ctxsrv_service'], File['ctxfarm_join_responsefile']],
    }
  }
}
