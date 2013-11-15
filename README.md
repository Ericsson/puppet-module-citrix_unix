puppet-module-citrix_unix
=========================

Puppet module to manage Citrix Presentation Server for UNIX

===

Example use:

<pre>
include citrix_unix::farm
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
citrix_unix::farm::is_master: 'true'
citrix_unix::farm::farm_name: 'farm-name'

citrix_unix::farm::applications:
  'Solaris10xterm':
    command: 'tcsh -c "/usr/openwin/bin/xterm -title `hostname`"'
    passphrase: 'secret'
    use_ssl: 'yes'
    groups:
      - citrixusers
</pre>

Farm slave:
<pre>
---
citrix_unix::farm::farm_name: 'farm-name'
citrix_unix::farm::master: 'master-server'
citrix_unix::farm::passphrase: 'secret'
</pre>
