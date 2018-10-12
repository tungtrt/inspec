# All tests in this file exercise resources that directly use `file`.

# This file is written by the test harness and chmodded to 000
unreadable_file_path = ENV['INSPEC_FUNCTEST_UNREADABLE_FILE']

control 'fail_file_direct_file_not_found_content' do
  # Correct behavior is to fail,
  # with error message prefixed with 'Unable to test'
  describe file('/no/such/path') do
    its('content') { should be_nil }
  end
end

control 'fail_file_direct_unreadable_content' do
  # Correct behavior is to fail,
  # with error message prefixed with 'Unable to test'
  describe file(unreadable_file_path) do
    its('content') { should be_nil }
  end
end

control 'pass_file_direct_file_not_found_exist' do
  # Correct behavior is to pass, do not raise unable
  describe file('/no/such/path') do
    it { should_not exist }
  end
end

control 'pass_file_direct_unreadable_readable' do
  # Correct behavior is to fail,
  # with error message prefixed with 'Unable to test'
  describe file(unreadable_file_path) do
    it { should_not be_readable } # TODO: check matcher args
  end
end

# TODO: concievably, have a timeout test (eg a network drive)