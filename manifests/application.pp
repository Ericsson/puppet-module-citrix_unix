# == Define: citrix_unix::application
define citrix_unix::application(
  $appname    = $name,
  $members    = ['*'],
  $command    = undef,
  $colordepth = '24bit',
  $windowsize = '95%',
  $users      = undef,
  $groups     = undef,
  $use_ssl    = 'yes',
) {

  validate_array($members)
  validate_string($colordepth)
  validate_string($windowsize)
  validate_re($use_ssl, ['^yes','^no'])
  if $command {
    validate_string($command)
  }
  if $users {
    validate_array($users)
  }
  if $groups {
    validate_array($groups)
  }

  $farm_members_str = join($members, ',')

  if $command {
    $mycommand = regsubst($command,'"','\"','G')
  } else {
    $mycommand = '' # lint:ignore:empty_string_assignment
  }

  $appname_md5 = md5($appname)
  $responsefile_path = "${citrix_unix::ctxappcfg_responsefile_base_path}/ctxappcfg_${appname_md5}.response"

  file { "ctxappcfg_responsefile_${appname_md5}":
    ensure  => file,
    path    => $responsefile_path,
    mode    => $citrix_unix::ctxappcfg_responsefile_mode,
    owner   => $citrix_unix::ctxappcfg_responsefile_owner,
    group   => $citrix_unix::ctxappcfg_responsefile_group,
    content => template('citrix_unix/ctxappcfg_responsefile.erb'),
  }

  exec { "ctxappcfg-${appname_md5}":
    path    => '/opt/CTXSmf/sbin:/opt/CTXSmf/bin:/bin:/usr/bin:/usr/local/bin',
    command => "ctxappcfg >/dev/null < ${responsefile_path}",
    unless  => "ctxqserver -app ${citrix_unix::farm_master} | grep -i \"^${appname}\"",
    require => [Service['ctxsrv_service'], File["ctxappcfg_responsefile_${appname_md5}"]],
  }
}
