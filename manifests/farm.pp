# == Class: citrix_unix::farm
#
# Module to manage Citrix Presentation Server for UNIX
#
class citrix_unix::farm (
  $is_master    = false,
  $name         = undef,
  $master       = undef,
  $passphrase   = $name,
  $applications = undef,
) inherits citrix_unix {

  if $is_master == true {
    file { 'ctxfarm_create_responsefile':
      ensure  => file,
      path    => $citrix_unix::ctxfarm_create_response_path,
      mode    => $citrix_unix::ctxfarm_responsefile_mode,
      owner   => $citrix_unix::ctxfarm_responsefile_owner,
      group   => $citrix_unix::ctxfarm_responsefile_group,
      content => "${name}\n${passphrase}\n${passphrase}\n",
    }

    # TODO : verify command to check if farm is created
    exec { "ctxfarm_create_${name}":
      command => "/opt/CTXSmf/sbin/ctxfarm -c < ${citrix_unix::ctxfarm_create_response_path}",
      unless  => "/opt/CTXSmf/sbin/ctxfarm -l | grep ${name}",
      require => File['ctxfarm_create_responsefile'],
    }

    # TODO : Add create_resources for "applications"
#    if $applications {
#      create_resources('citrix_unix::applications', $applications)
#    }

  } else {
    file { 'ctxfarm_join_responsefile':
      ensure  => file,
      path    => $citrix_unix::ctxfarm_join_response_path,
      mode    => $citrix_unix::ctxfarm_responsefile_mode,
      owner   => $citrix_unix::ctxfarm_responsefile_owner,
      group   => $citrix_unix::ctxfarm_responsefile_group,
      content => "${name}\n${passphrase}\n${master}\n",
    }

    # TODO : verify command to check farm join
    exec { "ctxfarm_join_${name}":
      command => "/opt/CTXSmf/sbin/ctxfarm -j < ${citrix_unix::ctxfarm_join_response_path}",
      unless  => "/opt/CTXSmf/sbin/ctxfarm -l | grep -i ${::hostname}",
      require => File['ctxfarm_join_responsefile'],
    }
  }
}
