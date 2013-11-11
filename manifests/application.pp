# == Define: citrix_unix::application
define citrix_unix::application(
  $appname    = $name,
  $members,
  $command    = undef,
  $colordepth = '24bit',
  $windowsize = '95%',
) {

  $responsefile_path = "${citrix_unix::ctxappcfg_responsefile_base_path}/ctxappcfg_${appname}.response"

  if $command {
    $mycommand = regsubst($command,'"','\"','G')
  } else {
    $mycommand = ''
  }

  $farm_members_str = join($members, ',')

  file { "ctxappcfg_responsefile_${appname}":
    ensure  => file,
    path    => $responsefile_path,
    mode    => $citrix_unix::ctxappcfg_responsefile_mode,
    owner   => $citrix_unix::ctxappcfg_responsefile_owner,
    group   => $citrix_unix::ctxappcfg_responsefile_group,
    content => template('citrix_unix/ctxappcfg_response.erb'),
  }

  exec { "ctxappcfg-${appname}":
    path    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
    command => "ctxappcfg >/dev/null < ${responsefile_path}",
    #unless => "# command to list applications",
    require => File["ctxappcfg_responsefile_${appname}"],
  }
}
