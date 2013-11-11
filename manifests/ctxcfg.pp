# Define: citrix_unix::ctxcfg
define citrix_unix::ctxcfg() {

  $parameter = $name
  $name_md5 = md5($name)

  exec { "ctxcfg-${name_md5}":
    path   => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
    comand => "ctxcfg ${parameter}",
    unless => "ctxcfg -g | grep \"${parameter}\"",
  }

}
