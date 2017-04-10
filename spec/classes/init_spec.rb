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
        'refreshonly' => true,
        'cwd'         => '/var/tmp',
        'command'     => 'patchadd -M . ', # this looks fishy, guess that $ctx_patch_name should be mandatory
        'timeout'     => '60',
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
  end

  context 'with default params on unsupported osfamily Redhat' do
    let(:facts) { { :osfamily => 'RedHat' } }

    it 'should fail' do
      expect {
        should contain_class('citrix_unix')
      }.to raise_error(Puppet::Error,/citrix_unix is supported on osfamily Solaris/)
    end
  end

  describe 'with ctxssl_config_owner set to valid string spectester' do
    let(:params) { mandatory_params.merge({ :ctxssl_config_owner => 'spectester' }) }
    it { should contain_file('ctx_ssl_config').with_owner('spectester') }
  end

  describe 'with ctxssl_config_group set to valid string specgroup' do
    let(:params) { mandatory_params.merge({ :ctxssl_config_group => 'specgroup' }) }
    it { should contain_file('ctx_ssl_config').with_group('specgroup') }
  end

  describe 'with package_name set to valid string CTXSmf-x86' do
    let(:params) { mandatory_params.merge({ :package_name => 'CTXSmf-x86' }) }
    it { should contain_package('ctxsmf_package').with_name('CTXSmf-x86') }
  end
end
