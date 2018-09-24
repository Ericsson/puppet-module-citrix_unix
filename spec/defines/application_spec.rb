require 'spec_helper'
describe 'citrix_unix::application' do
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
    content_ctxappcfg_responsefile = <<-END.gsub(/^\s+\|/, '')
      |publish
      |rspec-title
      |
      |
      |no
      |
      |
      |
      |95%
      |24bit
      |yes
      |
      |
      |*
      |
      |exit
    END

    it { should compile.with_all_deps }
    it do
      should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with({
        'ensure'  => 'file',
        'path'    => '/var/CTXSmf/ctxappcfg_06832991b731a501a792f7e8763ef5c2.response',
        'mode'    => '0640',
        'owner'   => 'root',
        'group'   => 'root',
        'content' => content_ctxappcfg_responsefile,
      })
    end

    it do
      should contain_exec('ctxappcfg-06832991b731a501a792f7e8763ef5c2').with({
        'path'    => '/opt/CTXSmf/sbin:/opt/CTXSmf/bin:/bin:/usr/bin:/usr/local/bin',
        'command' => 'ctxappcfg >/dev/null < /var/CTXSmf/ctxappcfg_06832991b731a501a792f7e8763ef5c2.response',
        'unless'  => 'ctxqserver -app spectest.farm.master | grep -i "^rspec-title"',
        'require' => ['Service[ctxsrv_service]', 'File[ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2]'],
      })
    end
    # it { pp catalogue.resources } # used to determine the generated md5 for the file name
  end

  describe 'with appname set to valid string test' do
    let(:params) { { :appname => 'test' } }
    it { should contain_file('ctxappcfg_responsefile_098f6bcd4621d373cade4e832627b4f6').with_path('/var/CTXSmf/ctxappcfg_098f6bcd4621d373cade4e832627b4f6.response') }
    it do
      should contain_exec('ctxappcfg-098f6bcd4621d373cade4e832627b4f6').with({
        'command' => 'ctxappcfg >/dev/null < /var/CTXSmf/ctxappcfg_098f6bcd4621d373cade4e832627b4f6.response',
        'unless'  => 'ctxqserver -app spectest.farm.master | grep -i "^test"',
        'require' => ['Service[ctxsrv_service]', 'File[ctxappcfg_responsefile_098f6bcd4621d373cade4e832627b4f6]'],
      })
    end
    # it { pp catalogue.resources } # used to determine the generated md5 for the file name
  end

  describe 'with members set to valid array %w(test1 test2)' do
    let(:params) { { :members => %w(test1 test2) } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^test1,test2\n\nexit\n$}) }
  end

  describe 'with command set to valid string test' do
    let(:params) { { :command => 'test' } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^publish\nrspec-title\ntest\n$}) }
  end

  describe 'with colordepth set to valid string 16bit' do
    let(:params) { { :colordepth => '16bit' } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^95%\n16bit\nyes\n$}) }
  end

  describe 'with windowsize set to valid string 42%' do
    let(:params) { { :windowsize => '42%' } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^42%\n24bit\nyes\n$}) }
  end

  describe 'with users set to valid array %w(user)' do
    let(:params) { { :users => %w(user) } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^95%\n24bit\nyes\nuser\n$}) }
  end

  describe 'with users set to valid array %w(user1 user2)' do
    let(:params) { { :users => %w(user1 user2) } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^95%\n24bit\nyes\nuser1\nuser2\n$}) }
  end

  describe 'with groups set to valid array %w(group)' do
    let(:params) { { :groups => %w(group) } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^95%\n24bit\nyes\n\ngroup\n$}) }
  end

  describe 'with groups set to valid array %w(group1 group2)' do
    let(:params) { { :groups => %w(group1 group2) } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^95%\n24bit\nyes\n\ngroup1\ngroup2\n$}) }
  end

  describe 'with use_ssl set to valid string no' do
    let(:params) { { :use_ssl => 'no' } }
    it { should contain_file('ctxappcfg_responsefile_06832991b731a501a792f7e8763ef5c2').with_content(%r{^95%\n24bit\nno\n$}) }
  end

  describe 'variable data type and content validations' do
    validations = {
      'Array' => {
        :name    => %w(members users groups),
        :valid   => [%w(array)],
        :invalid => ['string', { 'ha' => 'sh' }, 3, 2.42, true, nil],
        :message => 'is not an Array',
      },
      'Regex (yes|no)' => {
        :name    => %w(use_ssl),
        :valid   => %w(yes no),
        :invalid => ['string', %w(array), { 'ha' => 'sh' }, 3, 2.42, true, nil],
        :message => 'is not a string( containing yes or no)?',
      },
      'String' => {
        :name    => %w(colordepth windowsize command),
        :valid   => %w(string),
        :invalid => [%w(array), { 'ha' => 'sh' }, 3, 2.42, true],
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
