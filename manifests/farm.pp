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

    exec { "ctxfarm_create_${farm_name}":
      path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
      command => "ctxfarm -c < ${citrix_unix::ctxfarm_create_response_path}",
      unless  => "ctxfarm -l | grep ${farm_name}",
      require => [Service['ctxsrv_service'], File['ctxfarm_create_responsefile']],
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

    exec { "ctxfarm_join_${farm_name}":
      path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
      command => "ctxfarm -j < ${citrix_unix::ctxfarm_join_response_path}",
      unless  => "ctxfarm -l | grep -i ${::hostname}",
      require => [Service['ctxsrv_service'], File['ctxfarm_join_responsefile']],
    }
  }
}
