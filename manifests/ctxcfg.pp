# Define: citrix_unix::ctxcfg
define citrix_unix::ctxcfg() {

  $parameter = $name
  $name_md5 = md5($name)

  $parameter_grep = regsubst($parameter, '-', '\-', 'G')

  exec { "ctxcfg-${name_md5}":
    path    => '/opt/CTXSmf/sbin:x/bin:/usr/bin:/usr/local/bin',
    command => "ctxcfg ${parameter}",
    unless  => "ctxcfg -g | grep \'${parameter_grep}\'",
  }
}
