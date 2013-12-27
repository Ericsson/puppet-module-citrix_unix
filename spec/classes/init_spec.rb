require 'spec_helper'
describe 'citrix_unix' do

  context 'with class defaults on osfamily Solaris' do
    let :facts do
      {
        :osfamily => 'Solaris',
      }
    end

    it 'should fail' do
      expect {
        should contain_class('citrix_unix')
      }.to raise_error(Puppet::Error,/ctx_patch_base_path must be set to a absolute path/)
    end
  end

  context 'with specfiying package name, source, responsefile and adminfile on osfamily Solaris' do
    let :facts do
      {
        :osfamily => 'Solaris',
      }
    end
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

end
