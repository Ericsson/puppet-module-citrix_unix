require 'spec_helper'
describe 'citrix_unix' do
  mandatory_params = {
    :ctx_patch_base_path  => '/var/tmp',
    :package_source       => '/var/tmp/CTXSmf.pkg',
    :package_responsefile => '/var/tmp/pkg.response',
    :package_adminfile    => '/var/tmp/pkg.admin',
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

  context 'with specfiying package name, source, responsefile and adminfile on osfamily Solaris' do
    let (:params) {
      {
        :ctx_patch_base_path => '/var/tmp',
        :package_name   => 'CTXSmf-x86',
        :package_source => '/var/tmp/CTXSmf.pkg',
        :package_responsefile => '/var/tmp/pkg.response',
        :package_adminfile => '/var/tmp/pkg.admin',
      }
    }

    it do
      should contain_package('ctxsmf_package').with({
        'ensure'       => 'installed',
        'name'         => 'CTXSmf-x86',
        'source'       => '/var/tmp/CTXSmf.pkg',
        'responsefile' => '/var/tmp/pkg.response',
        'adminfile'    => '/var/tmp/pkg.admin',
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
  end

  context 'on unsupported osfamily' do
    let :facts do
      {
        :osfamily => 'RedHat',
      }
    end

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

end
