require 'spec_helper'
describe 'citrix_unix::ctxcfg' do
  let(:title) { 'rspec-title' }
  let(:pre_condition) do
    <<-'ENDofPUPPETcode'
    class { '::citrix_unix':
      ctx_patch_base_path  => '/var/tmp',
      package_source       => '/var/tmp/CTXSmf.pkg',
      package_responsefile => '/var/tmp/pkg.response',
      package_adminfile    => '/var/tmp/pkg.admin',
      farm_name            => 'spectestfarm',
      farm_master          => 'spectest.farm.master',
      farm_passphrase      => 'spectestfarm_passphrase',
      license_flexserver   => 'ctx-lic.spectest.com',
    }
    ENDofPUPPETcode
  end

  describe 'with defaults for all parameters' do
    it { should compile.with_all_deps }
    it do
      should contain_exec('ctxcfg-06832991b731a501a792f7e8763ef5c2').with({
        'path'    => '/opt/CTXSmf/sbin:x/bin:/usr/bin:/usr/local/bin',
        'command' => 'ctxcfg rspec-title',
        'unless'  => 'ctxcfg -g | grep \'rspec\-title\'',
        'require' => 'Service[ctxsrv_service]',
      })
    end
    # it { pp catalogue.resources } # used to determine the generated md5 for the exec name
  end
end
