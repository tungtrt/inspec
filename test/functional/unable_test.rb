# Test inspec under conditions in which it is unable to perform checks.
require 'functional/helper'

module UnableFuncTestHelper
  let(:unable_fixtures_path) { File.join(profile_path, 'unable') }
  let(:files_path) { File.join(unable_fixtures_path, 'files') }
  let(:controls_path) { File.join(unable_fixtures_path, 'resources', 'controls') }
  let(:command) { "exec #{fixture_path}"}
  let(:run_result) do
    pre_run
    run_inspec_process(command, json: true, env: env)
  end
  let(:control_structs) { run_result.payload.json["profiles"][0]["controls"] }
  # Make id-status and id-message pairs for easier examination
  let(:control_statuses) { control_structs.map { |c| { id: c["id"], status: c["results"][0]["status"] } } }
  let(:control_messages) { control_structs.map { |c| { id: c["id"], message: c["results"][0]["message"] } } }
  let(:pre_run) { }
  let(:env) { { } }
end

describe 'Resources unable to run in controls' do
  include FunctionalHelper
  include UnableFuncTestHelper

  # Each control ID begins with either 'pass' or 'fail'. That sets up our expectations for each.
  # The reject-must contruction is used here so that if this expectation fails,
  # we'll get an error message containing the ID of the control that failed our expectation
  # "Consider the controls named pass_; throw out any that have the status 'passed'; you should be left with nothing"

  # Case A-01
  describe 'direct file controls' do
    let(:fixture_path) { File.join(controls_path, 'file.rb') }
    let(:pre_run) do
      # Make an unreadable file in a location that the profile can find
      file_path = File.join(files_path, 'unreadable_file')
      File.write(file_path, 'unreadable content')
      FileUtils.chmod(0000, file_path)
      env['INSPEC_FUNCTEST_UNREADABLE_FILE'] = file_path
    end

    it 'should evaluate controls with correct message prefix' do
      run_result.stderr.must_be_empty
      run_result.exit_status.wont_equal 1

      control_statuses.select { |s| s[:id].start_with?('pass') }.reject { |s| s[:status] == "passed" }.must_be_empty
      control_statuses.select { |s| s[:id].start_with?('fail') }.reject { |s| s[:status] == "failed" }.must_be_empty
      control_messages.select { |s| s[:id].start_with?('fail') }.reject { |m| m[:message].start_with?('Unable to test: ') }.must_be_empty
    end
  end
end

# describe 'Unable resource in various scopes' do
# end

# Suite A - Resources and Basic Ability

# Case A-02
# When a profile contains a shadow resource,    # <--- or any other resource that uses file(), perhaps several layers down
#  and the file does not exist,
#  and the control performs a negative user check
#  then the resource generates an UnAble exception subclass
#  then the control fails with the message that the underlying file does not exist

# Case A-03
# When a profile contains a command resource,
#  and the named command does not exist on the system,
#  and the control performs a negative stdout test,
#  then the resource generates an UnAble exception subclass
#  then the control should fail with the message that the underlying command is missing

# Case A-04
# When a profile contains a http resource,    # <--- or any other resource that uses command(), perhaps several layers down
#  and the curl is not installed on the system
#  and the control performs a negative body check
#  then the resource generates an UnAble exception subclass
#  then the control fails with the message that curl is not installed

# Case A-05
# When a database control attempts to connect to a database,
#  and the network connection times out
#  and the control contains a negative test,
#  then the resource generates an UnAble exception subclass
#  then the control should fail with a timeout message

# Case A-06
# When a cloud-based resource is used to locate a cloud object by id
#  and the search is a miss
#  and the control contains any test other than an existance check
#  then the resource generates an UnAble exception subclass
#  then the control should fail with information about the missing cloud object

# Suite B - Privilege

# Case B-01
# When a resource is used that would require sudo (???)  # <-- aside from manual inspection, how would we know?
#  and the target is run without elevated permissions
#  then the resource generates an UnAble exception subclass
#  then the control should fail with the message that the sudo is required to use the control

# Case B-02
# When a resource is used that would write to the target disk
#  and that is not permitted (? how so? inspec config?  attempt and fail?)
#  then the resource generates an UnAble exception subclass
#  then the control should fail with the message that write access is needed for that control

# Case B-03
# When a cloud-based resource is used
#  and the credentials are correct for basic authentication
#  and the credentials do not allow a specific needed operation
#  then the resource generates an UnAble exception subclass
#  then the control should fail with information about the needed permission

# Suite C - Conditionalized Handling

# Case C-01
# When a control is unable to be executed
#  and there is no other unable-handling condition in place
#  then the resource generates an UnAble exception subclass
#  then the control should fail

# Case C-02
# When a control is unable to be executed
#  and there is a skip_on_unable (DSL statement? block?)
#  then the resource generates an UnAble exception subclass
#  then the control should skip

# Case C-03
# When profile W wraps profile D
#  and profile D contains a control C that cannot be executed
#  and profile W overrides the control C, adding the DSL 'skip_on_unable'
#  and profile W is executed
#  then the resource generates an UnAble exception subclass
#  then the control will be skipped

# Case C-04
# When profile W wraps profile D
#  and profile D contains a control C that cannot be executed
#  and control C contains the DSL statement 'skip_on_unable'
#  and profile W overrides the control, adding the DSL 'fail_on_unable'
#  and profile W is executed
#  then the resource generates an UnAble exception subclass
#  then the control will fail

#----------------------------------

# Future work:
#   Unable-type exceptions lay the groundwork for intercepting network access attempts
#     especially if a block approach is used
#     foundation for airgap support
#   Unable-type exceptions lay the groundwork for intercepting filesystem access attempts
#     foundation for selinux/etc support
#     foundation for --no-write option
#     foundation for auditing fs access