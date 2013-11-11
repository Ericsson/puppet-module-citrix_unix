puppet-module-citrix_unix
=========================

Puppet module to manage Citrix Presentation Server for UNIX

===

Example hiera config:

<pre>
---
citrix_unix::ctxsrvr_user_home: '/home/citrix'
citrix_unix::ctxssl_user_home: '/home/citrix'
citrix_unix::ctx_patch_base_path: '/var/tmp/Citrix/hotfix'
citrix_unix::ctx_patch_name: 'PSE400SOL067'
citrix_unix::package_source: '/var/tmp/Citrix/solaris/CTXSmf'
citrix_unix::package_responsefile: '/var/tmp/Citrix/solaris/response'
citrix_unix::package_adminfile: '/var/tmp/Citrix/solaris/admin'

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
  - '-k nomorelogons=1'
</pre>

Farm master:
<pre>
---
citrix_unix::farm::is_master: 'true'
citrix_unix::farm::name: 'farm-name'
</pre>

Farm slave:
<pre>
---
citrix_unix::farm::name: 'farm-name'
citrix_unix::farm::master: 'master-server'
citrix_unix::farm::passphrase: 'secret'
</pre>
