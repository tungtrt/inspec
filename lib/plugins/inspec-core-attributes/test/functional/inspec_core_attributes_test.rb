# encoding: utf-8
require_relative '../helper'

# This module assists in running a subprocess that calls Inspec::Runner.new
# module RunnerRunnerHelper
#   include FunctionalHelper

#   TRAIN_CONN = Train.create('local', command_runner: :generic).connection

#   let(:runner_script) { '' }
#   def run_runner(opts)
#     opts # ... TODO
#   end
# end

describe 'setting attributes by single methods' do
  include FunctionalHelper

  let(:plugin_fixtures_path) { File.join(repo_path, 'lib', 'plugins', 'inspec-core-attributes', 'test', 'fixtures')}
  let(:profile_path) { File.join(plugin_fixtures_path, 'profiles', profile_name)}
  let(:attr_file_path) { File.join(profile_path, 'attribute_files', attr_file_name + '.yaml')}
  let(:run_result) { run_inspec_process(invocation, json: true) }
  let(:json_results) { run_result.payload.json['profiles'][0]['controls'][0]['results'] }

  #--------------------------------------------------------------------------------#
  #                            Attributes via Runner API
  #--------------------------------------------------------------------------------#
  # # TODO: Add tests that call Inspec.runner with :attributes option, like audit cookbook and kitchen-inspec do
  # describe 'using a direct call to Runner' do
  # end

  #--------------------------------------------------------------------------------#
  #                            Attributes via --attrs
  #--------------------------------------------------------------------------------#
  describe 'using the --attrs option' do
    let(:invocation) { 'exec ' + profile_path + ' --attrs ' + attr_file_path + ' --controls ' + attr_file_name}
    let(:profile_name) { 'basic_attributes' }
    [
      'flat',
      'nested',
    ].each do |attr_file|
      let(:attr_file_name) { attr_file }
      it "runs OK on #{attr_file} attributes" do
        run_result.stderr.must_be_empty
        json_results.each do |result|
          (result['code_desc'] + ': ' + result['status']).must_equal(result['code_desc'] + ': success')
        end
      end
    end
  end

  #--------------------------------------------------------------------------------#
  #                            Attributes in Metadata
  #--------------------------------------------------------------------------------#
  describe 'using attributes in profile metadata' do
    let(:invocation) { 'exec ' + profile_path + ' --controls ' + control_focus }

    describe 'when the profile contains simple metadata' do
      let(:profile_name) { 'metadata_attributes' }

      {
        'basic-pass' => 'when a basic attribute is read'
      }.each do |focus_group, group_label|
        describe group_label do
          let(:control_focus) { focus_group }
          it 'passes all tests' do
            run_result.stderr.must_be_empty
            json_results.each do |result|
              (result['code_desc'] + ': ' + result['status']).must_equal(result['code_desc'] + ': success')
            end
          end
        end
      end

      describe 'when no attribute is defined anywhere' do
        let(:control_focus) { 'basic-fail' }
        it 'fails' do
          run_result.stderr.must_be_empty
          json_results # TODO
        end
      end
    end

    #describe 'when the profile contains empty metadata attributes' do
      #   it "does not error when attributes are empty" do
  #     cmd = 'exec '
  #     cmd += File.join(profile_path, 'profile-with-empty-attributes')
  #     cmd += ' --no-create-lockfile'
  #     out = inspec(cmd)
  #     out.stdout.must_include 'WARN: Attributes must be defined as an Array. Skipping current definition.'
  #     out.exit_status.must_equal 0
  #   end
    #end

    #describe 'when the profile contains invalid metadata attribute entries' do

  #   it "errors with invalid attribute types" do
  #     cmd = 'exec '
  #     cmd += File.join(profile_path, 'invalid_attributes')
  #     cmd += ' --no-create-lockfile'
  #     out = inspec(cmd)
  #     out.stderr.must_equal "Type 'Color' is not a valid attribute type.\n"
  #     out.stdout.must_equal ''
  #     out.exit_status.must_equal 1
  #   end

  end
end
