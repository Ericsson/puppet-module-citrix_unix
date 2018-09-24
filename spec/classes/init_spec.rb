require 'spec_helper'
describe 'citrix_unix' do
  mandatory_params = {
    :ctx_patch_base_path  => '/var/tmp',
    :package_source       => '/var/tmp/CTXSmf.pkg',
    :package_responsefile => '/var/tmp/pkg.response',
    :package_adminfile    => '/var/tmp/pkg.admin',
    # these parameters are actually mandatory and should be tested
    :farm_name            => 'spectestfarm',
    :farm_master          => 'spectestfarmmaster',
    :farm_passphrase      => 'spectestfarm_passphrase',
    :license_flexserver   => 'ctx-lic.spectest.com',
  }
  let(:params) { mandatory_params }

  # valid hash for applications paramter used in later tests
  applications_hash = {
    :Solaris10xterm => {
      'command' => 'tcsh -c "/usr/openwin/bin/xterm -title `hostname`"',
      'use_ssl' => 'yes',
      'groups'  => %w(citrixusers),
    },
    :Solaris10xterm2 => {
      'command' => 'tcsh -c "/usr/openwin/bin/xterm2 -title `hostname`"',
      'use_ssl' => 'yes',
      'groups'  => %w(citrixusers2),
    },
  }

  # a valid array for ctxcfg_parameters used in later tests
  ctxcfg_parameters_array = [
    '-s enable,input=ON,notify=ON',
    '-p enable',
    '-e none',
    '-c broken=DISCONNECT,reconnect=ANY',
  ]

  context 'with default params on supported osfamily Solaris' do
    let(:params) { {} } # ignore mandatory params

    it 'should fail' do
      expect {
        should contain_class('citrix_unix')
      }.to raise_error(Puppet::Error,/ctx_patch_base_path must be set to a absolute path/)
    end
  end

  context 'with mandatory params set on farm member' do
    it do
      should contain_group('ctxadm_group').with({
        'ensure' => 'present',
        'name'   => 'ctxadm',
        'gid'    => '796',
      })
    end

    it do
      should contain_user('ctxsrvr_user').with({
        'ensure'     => 'present',
        'name'       => 'ctxsrvr',
        'uid'        => '11512',
        'gid'        => '796',
        'home'       => '/home/ctxsrvr',
        'shell'      => '/bin/tcsh',
        'managehome' => true,
        'require'    => 'Group[ctxadm_group]',

      })
    end

    it do
      should contain_user('ctxssl_user').with({
        'ensure'     => 'present',
        'name'       => 'ctxssl',
        'uid'        => '47094',
        'gid'        => '796',
        'home'       => '/home/ctxssl',
        'shell'      => '/bin/tcsh',
        'managehome' => true,
        'require'    => 'Group[ctxadm_group]',

      })
    end

    it do
      should contain_package('ctxsmf_package').with({
        'ensure'       => 'installed',
        'name'         => 'CTXSmf',
        'description'  => 'Citrix MetaFrame Presentation Server 4.0',
        'provider'     => 'sun',
        'vendor'       => 'Citrix Systems Inc',
        'source'       => '/var/tmp/CTXSmf.pkg',
        'responsefile' => '/var/tmp/pkg.response',
        'adminfile'    => '/var/tmp/pkg.admin',
        'require'      => ['User[ctxsrvr_user]','User[ctxssl_user]'],
        'notify'       => 'Exec[ctxpatch]',
      })
    end

    it do
      should contain_exec('ctxpatch').with({
        'path'        => '/bin:/usr/bin:/usr/local/bin:/usr/sbin',
        'cwd'         => '/var/tmp',
        'command'     => 'patchadd -M . ', # this looks fishy, guess that $ctx_patch_name should be mandatory
        'timeout'     => '60',
        'refreshonly' => true,
        'require'     => 'Package[ctxsmf_package]',
      })
    end

    ctx_ssl_config_content = <<-END.gsub(/^\s+\|/, '')
      |# This file is managed by Puppet. Do not edit manually.
      |#
      |# Copyright 2005 Citrix Systems, Inc.  All Rights Reserved.
      |#
      |SSL_ENABLED=1
      |
      |
    END

    it do
      should contain_file('ctx_ssl_config').with({
        'ensure'  => 'file',
        'path'    => '/var/CTXSmf/ssl/config',
        'mode'    => '0640',
        'owner'   => 'ctxssl',
        'group'   => 'ctxadm',
        'content' => ctx_ssl_config_content,
        'require' => 'Package[ctxsmf_package]',
        'notify'  => 'Service[ctxsrv_service]',
      })
    end

    it do
      should contain_service('ctxsrv_service').with({
        'ensure'   => 'running',
        'name'     => 'ctxsrv',
        'enable'   => false,
        'pattern'  => '/opt/CTXSmf/slib/ctxfm',
        'provider' => 'base',
        'start'    => '/opt/CTXSmf/sbin/ctxsrv start all',
        'require' => 'Package[ctxsmf_package]',
      })
    end

    it { should have_citrix_unix__ctxcfg_resource_count(0) }
    it { should_not contain_file('ctxfarm_create_responsefile') }
    it { should_not contain_exe('ctxfarm_create') }
    it { should_not contain_exe('license_config') }
    it { should have_application_resource_count(0) }

    ctxfarm_join_responsefile_content = <<-END.gsub(/^\s+\|/, '')
      |spectestfarm
      |spectestfarm_passphrase
      |spectestfarmmaster
    END

    it do
      should contain_file('ctxfarm_join_responsefile').with({
        'ensure'  => 'file',
        'path'    => '/var/CTXSmf/ctxfarm_join.response',
        'mode'    => '0640',
        'owner'   => 'root',
        'group'   => 'root',
        'content' => ctxfarm_join_responsefile_content,
        'require' => 'Package[ctxsmf_package]',
      })
    end

    it do
      should contain_exec('ctxfarm_join').with({
        'path'    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
        'command' => 'ctxfarm -j < /var/CTXSmf/ctxfarm_join.response',
        'unless'  => 'ctxfarm -l | grep -i spectesthost',
        'require' => [ 'Service[ctxsrv_service]', 'File[ctxfarm_join_responsefile]' ],
      })
    end
  end

  context 'with mandatory params set on farm master' do
    let(:params) { mandatory_params.merge({ :is_farm_master => true }) }
    # same resources as for farm members:
    it { should contain_group('ctxadm_group') }
    it { should contain_user('ctxsrvr_user') }
    it { should contain_user('ctxssl_user') }
    it { should contain_package('ctxsmf_package') }
    it { should contain_exec('ctxpatch') }
    it { should contain_file('ctx_ssl_config') }
    it { should contain_service('ctxsrv_service') }
    it { should have_citrix_unix__ctxcfg_resource_count(0) }

    # farm master specifics:
    ctxfarm_create_responsefile_content = <<-END.gsub(/^\s+\|/, '')
      |spectestfarm
      |spectestfarm_passphrase
      |spectestfarm_passphrase
    END

    it do
      should contain_file('ctxfarm_create_responsefile').with({
        'ensure'  => 'file',
        'path'    => '/var/CTXSmf/ctxfarm_create.response',
        'mode'    => '0640',
        'owner'   => 'root',
        'group'   => 'root',
        'content' => ctxfarm_create_responsefile_content,
        'require' => 'Package[ctxsmf_package]',
      })
    end

    it do
      should contain_exec('ctxfarm_create').with({
        'path'    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
        'command' => 'ctxfarm -c < /var/CTXSmf/ctxfarm_create.response',
        'unless'  => 'ctxfarm -l | grep spectestfarm',
        'require' => [ 'Service[ctxsrv_service]', 'File[ctxfarm_create_responsefile]' ],
      })
    end

    it do
      should contain_exec('license_config').with({
        'path'    => '/opt/CTXSmf/sbin:/bin:/usr/bin:/usr/local/bin',
        'command' => 'ctxlsdcfg -s ctx-lic.spectest.com -p 27000 -e Platinum -c post4.0 -m FeaturePack1',
        'unless'  => 'grep ^flexserver=ctx-lic.spectest.com /var/CTXSmf/ctxxmld.cfg',
        'require' => 'Service[ctxsrv_service]',
      })
    end

    it { should_not contain_file('ctxfarm_join_responsefile') }
    it { should_not contain_exec('ctxfarm_join') }

  end

  context 'with default params on unsupported osfamily Redhat' do
    let(:facts) { { :osfamily => 'RedHat' } }

    it 'should fail' do
      expect {
        should contain_class('citrix_unix')
      }.to raise_error(Puppet::Error,/citrix_unix is supported on osfamily Solaris/)
    end
  end

  describe 'with applications_hash set to valid hash when is_farm_master is true' do
    let(:params) { mandatory_params.merge({ :is_farm_master => true, :applications => applications_hash }) }
    it { should have_citrix_unix__application_resource_count(2) }
    it do
      should contain_citrix_unix__application('Solaris10xterm').with({
        'command' => 'tcsh -c "/usr/openwin/bin/xterm -title `hostname`"',
        'use_ssl' => 'yes',
        'groups'  => %w(citrixusers),
      })
    end
    it do
      should contain_citrix_unix__application('Solaris10xterm2').with({
        'command' => 'tcsh -c "/usr/openwin/bin/xterm2 -title `hostname`"',
        'use_ssl' => 'yes',
        'groups'  => %w(citrixusers2),
      })
    end
  end

  describe 'with ctxadm_group_name set to valid string tester' do
    let(:params) { mandatory_params.merge({ :ctxadm_group_name => 'tester' }) }
    it { should contain_file('ctx_ssl_config').with_group('tester') }
  end

  describe 'with ctxadm_group_name set to valid string tester when ctxssl_config_group is set to valid string group_override' do
    let(:params) { mandatory_params.merge({ :ctxadm_group_name => 'tester', :ctxssl_config_group => 'group_override' }) }
    it { should contain_file('ctx_ssl_config').with_group('group_override') }
  end

  describe 'with ctxadm_group_gid set to valid string 242' do
    let(:params) { mandatory_params.merge({ :ctxadm_group_gid => '242' }) }
    it { should contain_group('ctxadm_group').with_gid('242') }
  end

  describe 'with ctxsrvr_user_name set to valid string tester' do
    let(:params) { mandatory_params.merge({ :ctxsrvr_user_name => 'tester' }) }
    it { should contain_user('ctxsrvr_user').with_name('tester') }
  end

  describe 'with ctxsrvr_user_uid set to valid string 242' do
    let(:params) { mandatory_params.merge({ :ctxsrvr_user_uid => '242' }) }
    it { should contain_user('ctxsrvr_user').with_uid('242') }
  end

  describe 'with ctxsrvr_user_gid set to valid string 242' do
    let(:params) { mandatory_params.merge({ :ctxsrvr_user_gid => '242' }) }
    it { should contain_user('ctxsrvr_user').with_gid('242') }
  end

  describe 'with ctxsrvr_user_shell set to valid string /bin/bash' do
    let(:params) { mandatory_params.merge({ :ctxsrvr_user_shell => '/bin/bash' }) }
    it { should contain_user('ctxsrvr_user').with_shell('/bin/bash') }
  end

  describe 'with ctxsrvr_user_home set to valid string /home/tester' do
    let(:params) { mandatory_params.merge({ :ctxsrvr_user_home => '/home/tester' }) }
    it { should contain_user('ctxsrvr_user').with_home('/home/tester') }
  end

  describe 'with ctxsrvr_user_managehome set to valid boolean false' do
    let(:params) { mandatory_params.merge({ :ctxsrvr_user_managehome => false }) }
    it { should contain_user('ctxsrvr_user').with_managehome(false) }
  end

  describe 'with ctxssl_user_name set to valid string tester' do
    let(:params) { mandatory_params.merge({ :ctxssl_user_name => 'tester' }) }
    it { should contain_user('ctxssl_user').with_name('tester') }
  end

  describe 'with ctxssl_user_uid set to valid string 242' do
    let(:params) { mandatory_params.merge({ :ctxssl_user_uid => '242' }) }
    it { should contain_user('ctxssl_user').with_uid('242') }
  end

  describe 'with ctxssl_user_gid set to valid string 242' do
    let(:params) { mandatory_params.merge({ :ctxssl_user_gid => '242' }) }
    it { should contain_user('ctxssl_user').with_gid('242') }
  end

  describe 'with ctxssl_user_shell set to valid string /bin/bash' do
    let(:params) { mandatory_params.merge({ :ctxssl_user_shell => '/bin/bash' }) }
    it { should contain_user('ctxssl_user').with_shell('/bin/bash') }
  end

  describe 'with ctxssl_user_home set to valid string /home/tester' do
    let(:params) { mandatory_params.merge({ :ctxssl_user_home => '/home/tester' }) }
    it { should contain_user('ctxssl_user').with_home('/home/tester') }
  end

  describe 'with ctxssl_user_managehome set to valid boolean false' do
    let(:params) { mandatory_params.merge({ :ctxssl_user_managehome => false }) }
    it { should contain_user('ctxssl_user').with_managehome(false) }
  end

  describe 'with ctxssl_config_mode set to valid string 0242' do
    let(:params) { mandatory_params.merge({ :ctxssl_config_mode => '0242' }) }
    it { should contain_file('ctx_ssl_config').with_mode('0242') }
  end

  describe 'with ctxssl_config_owner set to valid string test' do
    let(:params) { mandatory_params.merge({ :ctxssl_config_owner => 'test' }) }
    it { should contain_file('ctx_ssl_config').with_owner('test') }
  end

  describe 'with ctxssl_config_group set to valid string test' do
    let(:params) { mandatory_params.merge({ :ctxssl_config_group => 'test' }) }
    it { should contain_file('ctx_ssl_config').with_group('test') }
  end

  describe 'with ctxssl_config_path set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :ctxssl_config_path => '/other/path' }) }
    it { should contain_file('ctx_ssl_config').with_path('/other/path') }
  end

  describe 'with ctxfarm_create_response_path set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :ctxfarm_create_response_path => '/other/path' }) }
    it { should_not contain_file('ctxfarm_create_responsefile') }
    it { should_not contain_exec('ctxfarm_create') }
  end

  describe 'with ctxfarm_create_response_path set to valid string /other/path when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :ctxfarm_create_response_path => '/other/path', :is_farm_master => true }) }
    it { should contain_file('ctxfarm_create_responsefile').with_path('/other/path') }
    it { should contain_exec('ctxfarm_create').with_command('ctxfarm -c < /other/path') }
  end

  describe 'with ctxfarm_join_response_path set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :ctxfarm_join_response_path => '/other/path' }) }
    it { should contain_file('ctxfarm_join_responsefile').with_path('/other/path') }
    it { should contain_exec('ctxfarm_join').with_command('ctxfarm -j < /other/path') }
  end

  describe 'with ctxfarm_join_response_path set to valid string /other/path when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :ctxfarm_join_response_path => '/other/path', :is_farm_master => true }) }
    it { should_not contain_file('ctxfarm_join_responsefile') }
    it { should_not contain_exec('ctxfarm_join') }
  end

  describe 'with ctxfarm_responsefile_mode set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :ctxfarm_responsefile_mode => '0242' }) }
    it { should contain_file('ctxfarm_join_responsefile').with_mode('0242') }
  end

  describe 'with ctxfarm_responsefile_mode set to valid string /other/path when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :ctxfarm_responsefile_mode => '0242', :is_farm_master => true }) }
    it { should contain_file('ctxfarm_create_responsefile').with_mode('0242') }
  end

  describe 'with ctxfarm_responsefile_owner set to valid string test' do
    let(:params) { mandatory_params.merge({ :ctxfarm_responsefile_owner => 'test' }) }
    it { should contain_file('ctxfarm_join_responsefile').with_owner('test') }
  end

  describe 'with ctxfarm_responsefile_owner set to valid string test when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :ctxfarm_responsefile_owner => 'test', :is_farm_master => true }) }
    it { should contain_file('ctxfarm_create_responsefile').with_owner('test') }
  end

  describe 'with ctxfarm_responsefile_group set to valid string test' do
    let(:params) { mandatory_params.merge({ :ctxfarm_responsefile_group => 'test' }) }
    it { should contain_file('ctxfarm_join_responsefile').with_group('test') }
  end

  describe 'with ctxfarm_responsefile_group set to valid string test when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :ctxfarm_responsefile_group => 'test', :is_farm_master => true }) }
    it { should contain_file('ctxfarm_create_responsefile').with_group('test') }
  end

  # FIXME: this parameter is used in citrix_unix::application only and should eventually get moved there
  describe 'with ctxappcfg_responsefile_base_path set to valid string /other/path when applications is set to valid hash and is_farm_master is true' do
    let(:params) { mandatory_params.merge({ :ctxappcfg_responsefile_base_path => '/other/path', :applications => applications_hash, :is_farm_master => true }) }
    # it { pp catalogue.resources } # used to determine the generated md5 for the file name in citrix_unix::application
    it { should contain_file('ctxappcfg_responsefile_d31c4d0a5bb772a223bfee87bf9bd133').with_path('/other/path/ctxappcfg_d31c4d0a5bb772a223bfee87bf9bd133.response') } # Solaris10xterm
    it { should contain_file('ctxappcfg_responsefile_fca024fd5c3098c10a231253ae998eb9').with_path('/other/path/ctxappcfg_fca024fd5c3098c10a231253ae998eb9.response') } # Solaris10xterm2
  end

  # FIXME: this parameter is used in citrix_unix::application only and should eventually get moved there
  describe 'with ctxappcfg_responsefile_mode set to valid string 0242 when applications is set to valid hash and is_farm_master is true' do
    let(:params) { mandatory_params.merge({ :ctxappcfg_responsefile_mode => '0242', :applications => applications_hash, :is_farm_master => true }) }
    # it { pp catalogue.resources } # used to determine the generated md5 for the file name in citrix_unix::application
    it { should contain_file('ctxappcfg_responsefile_d31c4d0a5bb772a223bfee87bf9bd133').with_mode('0242') } # Solaris10xterm
    it { should contain_file('ctxappcfg_responsefile_fca024fd5c3098c10a231253ae998eb9').with_mode('0242') } # Solaris10xterm2
  end

  # FIXME: this parameter is used in citrix_unix::application only and should eventually get moved there
  describe 'with ctxappcfg_responsefile_owner set to valid string test when applications is set to valid hash and is_farm_master is true' do
    let(:params) { mandatory_params.merge({ :ctxappcfg_responsefile_owner => 'test', :applications => applications_hash, :is_farm_master => true }) }
    # it { pp catalogue.resources } # used to determine the generated md5 for the file name in citrix_unix::application
    it { should contain_file('ctxappcfg_responsefile_d31c4d0a5bb772a223bfee87bf9bd133').with_owner('test') } # Solaris10xterm
    it { should contain_file('ctxappcfg_responsefile_fca024fd5c3098c10a231253ae998eb9').with_owner('test') } # Solaris10xterm2
  end

  # FIXME: this parameter is used in citrix_unix::application only and should eventually get moved there
  describe 'with ctxappcfg_responsefile_group set to valid string test when applications is set to valid hash and is_farm_master is true' do
    let(:params) { mandatory_params.merge({ :ctxappcfg_responsefile_group => 'test', :applications => applications_hash, :is_farm_master => true }) }
    # it { pp catalogue.resources } # used to determine the generated md5 for the file name in citrix_unix::application
    it { should contain_file('ctxappcfg_responsefile_d31c4d0a5bb772a223bfee87bf9bd133').with_group('test') } # Solaris10xterm
    it { should contain_file('ctxappcfg_responsefile_fca024fd5c3098c10a231253ae998eb9').with_group('test') } # Solaris10xterm2
  end

  describe 'with ctxxmld_config_path set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :ctxxmld_config_path => '/other/path' }) }
    it { should_not contain_exec('license_config') }
  end

  describe 'with ctxxmld_config_path set to valid string /other/path when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :ctxxmld_config_path => '/other/path', :is_farm_master => true }) }
    it { should contain_exec('license_config').with_unless('grep ^flexserver=ctx-lic.spectest.com /other/path') }
  end

  describe 'with ctxcfg_parameters set to valid array' do
    let(:params) { mandatory_params.merge({ :ctxcfg_parameters => ctxcfg_parameters_array }) }
    it { should have_citrix_unix__ctxcfg_resource_count(4) }
    it { should contain_citrix_unix__ctxcfg('-s enable,input=ON,notify=ON') }
    it { should contain_citrix_unix__ctxcfg('-p enable') }
    it { should contain_citrix_unix__ctxcfg('-e none') }
    it { should contain_citrix_unix__ctxcfg('-c broken=DISCONNECT,reconnect=ANY') }
  end

  describe 'with ctx_patch_name set to valid string test' do
    let(:params) { mandatory_params.merge({ :ctx_patch_name => 'test' }) }
    it { should contain_exec('ctxpatch').with_command('patchadd -M . test') }
  end

  describe 'with ctx_patch_base_path set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :ctx_patch_base_path => '/other/path' }) }
    it { should contain_exec('ctxpatch').with_cwd('/other/path') }
  end

  describe 'with farm_name set to valid string test' do
    let(:params) { mandatory_params.merge({ :farm_name => 'test' }) }
    it { should contain_file('ctxfarm_join_responsefile').with_content("test\nspectestfarm_passphrase\nspectestfarmmaster\n") }
  end

  describe 'with farm_name set to valid string test when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :farm_name => 'test', :is_farm_master => true }) }
    it { should contain_file('ctxfarm_create_responsefile').with_content("test\nspectestfarm_passphrase\nspectestfarm_passphrase\n") }
    it { should contain_exec('ctxfarm_create').with_unless('ctxfarm -l | grep test') }
  end

  describe 'with farm_master set to valid string spec.test' do
    let(:params) { mandatory_params.merge({ :farm_master => 'spec.test' }) }
    it { should contain_file('ctxfarm_join_responsefile').with_content("spectestfarm\nspectestfarm_passphrase\nspec.test\n") }
  end

  describe 'with farm_master set to valid string spec.test when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :farm_master => 'spec.test', :is_farm_master => true }) }
    it { should_not contain_file('ctxfarm_join_responsefile') }
  end

  describe 'with farm_passphrase set to valid string test' do
    let(:params) { mandatory_params.merge({ :farm_passphrase => 'test' }) }
    it { should contain_file('ctxfarm_join_responsefile').with_content("spectestfarm\ntest\nspectestfarmmaster\n") }
  end

  describe 'with farm_passphrase set to valid string test when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :farm_passphrase => 'test', :is_farm_master => true }) }
    it { should contain_file('ctxfarm_create_responsefile').with_content("spectestfarm\ntest\ntest\n") }
  end

  describe 'with farm_passphrase unset' do
    let(:params) { mandatory_params.merge({ :farm_passphrase => :undef }) }
    it { should contain_file('ctxfarm_join_responsefile').with_content("spectestfarm\nspectestfarm\nspectestfarmmaster\n") }
  end

  describe 'with farm_passphrase unset when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :farm_passphrase => :undef, :is_farm_master => true }) }
    it { should contain_file('ctxfarm_create_responsefile').with_content("spectestfarm\nspectestfarm\nspectestfarm\n") }
  end

  describe 'with is_farm_master set to valid boolean true' do
    let(:params) { mandatory_params.merge({ :is_farm_master => true }) }
    it { should contain_file('ctxfarm_create_responsefile') }
    it { should contain_exec('ctxfarm_create') }
    it { should contain_exec('license_config') }
    it { should_not contain_file('ctxfarm_join_responsefile') }
    it { should_not contain_exec('ctxfarm_join') }
  end

  describe 'with is_farm_master set to valid boolean false' do
    let(:params) { mandatory_params.merge({ :is_farm_master => false }) }
    it { should_not contain_file('ctxfarm_create_responsefile') }
    it { should_not contain_exec('ctxfarm_create') }
    it { should_not contain_exec('license_config') }
    it { should contain_file('ctxfarm_join_responsefile') }
    it { should contain_exec('ctxfarm_join') }
  end

  describe 'with license_flexserver set to valid string spec.test when is_farm_master is set to true' do
    let(:params) { mandatory_params.merge({ :license_flexserver => 'spec.test', :is_farm_master => true }) }
    it do
      should contain_exec('license_config').with({
        'command' => 'ctxlsdcfg -s spec.test -p 27000 -e Platinum -c post4.0 -m FeaturePack1',
        'unless'  => 'grep ^flexserver=spec.test /var/CTXSmf/ctxxmld.cfg',
      })
    end
  end

  describe 'with package_name set to valid string test' do
    let(:params) { mandatory_params.merge({ :package_name => 'test' }) }
    it { should contain_package('ctxsmf_package').with_name('test') }
  end

  describe 'with package_provider set to valid string test' do
    let(:params) { mandatory_params.merge({ :package_provider => 'test' }) }
    it { should contain_package('ctxsmf_package').with_provider('test') }
  end

  describe 'with package_source set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :package_source => '/other/path' }) }
    it { should contain_package('ctxsmf_package').with_source('/other/path') }
  end

  describe 'with package_vendor set to valid string test' do
    let(:params) { mandatory_params.merge({ :package_vendor => 'test' }) }
    it { should contain_package('ctxsmf_package').with_vendor('test') }
  end

  describe 'with package_description set to valid string test' do
    let(:params) { mandatory_params.merge({ :package_description => 'test' }) }
    it { should contain_package('ctxsmf_package').with_description('test') }
  end

  describe 'with package_responsefile set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :package_responsefile => '/other/path' }) }
    it { should contain_package('ctxsmf_package').with_responsefile('/other/path') }
  end

  describe 'with package_adminfile set to valid string /other/path' do
    let(:params) { mandatory_params.merge({ :package_adminfile => '/other/path' }) }
    it { should contain_package('ctxsmf_package').with_adminfile('/other/path') }
  end

  describe 'with enable_ssl_relay set to valid boolean false' do
    let(:params) { mandatory_params.merge({ :enable_ssl_relay => false }) }
    it { should contain_file('ctx_ssl_config').with_content(%r{SSL_ENABLED=0}) }
  end

  describe 'variable data type and content validations' do
    validations = {
      'Array' => {
        :name    => %w(ctxcfg_parameters),
        :valid   => [%w(array)],
        :invalid => ['string', { 'ha' => 'sh' }, 3, 2.42, true, nil],
        :message => 'is not an Array',
      },
      'Filemode' => {
        :name    => %w(ctxssl_config_mode ctxssl_config_mode ctxssl_config_mode),
        :valid   => %w(0644 0755 0640 0740),
        :invalid => ['0844', '755', '00644', 'string', %w(array), { 'ha' => 'sh' }, 3, 2.42, false, nil],
        :message => '(is not a string|is not a file mode in octal notation)',
      },
      'Hash' => {
        :name    => %w[applications],
        :valid   => [], # valid hashes are to complex to block test them here. Subclasses have their own specific spec tests anyway.
        :invalid => ['string', 3, 2.42, %w[array], true, nil],
        :message => 'is not a Hash',
      },
      'Stdlib::Absolutepath' => {
        :name    => %w(ctxsrvr_user_shell ctxsrvr_user_home ctxssl_user_shell ctxssl_user_home ctxssl_config_path ctxfarm_create_response_path ctxfarm_join_response_path ctxappcfg_responsefile_base_path ctx_patch_base_path ctxxmld_config_path package_source package_responsefile package_adminfile),
        :valid   => ['/absolute/filepath', '/absolute/directory/'],
        :invalid => ['../invalid', %w(array), { 'ha' => 'sh' }, 3, 2.42, true, nil],
        :message => 'is not an absolute path',
      },
      'String' => {
        :name    => %w(farm_name ctxadm_group_name ctxsrvr_user_name ctxssl_user_name ctxfarm_responsefile_owner ctxfarm_responsefile_group ctxappcfg_responsefile_owner ctxappcfg_responsefile_group farm_name license_flexserver package_name package_vendor package_description),
        :valid   => %w(string),
        :invalid => [%w(array), { 'ha' => 'sh' }, 3, 2.42, false],
        :message => 'is not a string',
      },
      'String (package provider)' => {
        :name    => %w(package_provider),
        :valid   => %w(sunfreeware),
        :invalid => [%w(array), { 'ha' => 'sh' }, 3, 2.42, false],
        :message => 'is not a string',
      },
    }

    validations.sort.each do |type, var|
      mandatory_params = {} if mandatory_params.nil?
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:facts) { [mandatory_facts, var[:facts]].reduce(:merge) } if ! var[:facts].nil?
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid, }].reduce(:merge) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid, }].reduce(:merge) }
            it 'should fail' do
              expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
