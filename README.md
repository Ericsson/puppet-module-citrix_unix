puppet-module-citrix_unix
=========================

Puppet module to manage Citrix Presentation Server for UNIX

# Compatability #

This module has been tested to work on the following systems with the latest
Puppet v3, v3 with future parser, v4, v5 and v6. See `.travis.yml` for the
exact matrix of supported Puppet and ruby versions.

## OS Distributions ##

 * Solaris 9

===

Example use:

<pre>
include citrix_unix
</pre>

Example hiera config:

<pre>
---
citrix_unix::ctxsrvr_user_home: '/home/citrix'
citrix_unix::ctxssl_user_home: '/home/citrix'
citrix_unix::ctx_patch_base_path: '/net/server/Citrix/hotfix'
citrix_unix::ctx_patch_name: 'PSE400SOL067'
citrix_unix::license_flexserver: 'ctx-lic.example.com'
citrix_unix::package_source: '/net/server/Citrix/solaris/CTXSmf'
citrix_unix::package_responsefile: '/net/server/Citrix/solaris/response'
citrix_unix::package_adminfile: '/net/server/Citrix/solaris/admin'

citrix_unix::ctxcfg_parameters:
  - '-a prompt=FALSE,inherit'
  - '-l max=UNLIMITED'
  - '-P set=1494'
  - '-t connect=NONE,disconnect=28800,disclogoff=28800,authentication=20,idle=7200,clientcheck=1200,clientresponse=600'
  - '-c broken=DISCONNECT,reconnect=ANY'
  - '-p enable'
  - '-k disallowicaclient=1'
  - '-k logofflogging=1'
  - '-k logonlogging=2'
  - '-k reconnectlogging=2'
  - '-C enable'
  - '-e none'
  - '-s enable,input=ON,notify=ON'
  - '-m enable,lowerthreshold=150,upperthreshold=500'
  - '-D disable'
  - '-o set=100'
  - '-k nomorelogons=0'
</pre>

Farm master:
<pre>
---
citrix_unix::is_farm_master: 'true'
citrix_unix::farm_name: 'farm-name'

citrix_unix::applications:
  'Solaris10xterm':
    command: 'tcsh -c "/usr/openwin/bin/xterm -title `hostname`"'
    use_ssl: 'yes'
    groups:
      - citrixusers
</pre>

Farm slave:
<pre>
---
citrix_unix::farm_name: 'farm-name'
citrix_unix::farm_master: 'master-server'
citrix_unix::farm_passphrase: 'secret'
</pre>
