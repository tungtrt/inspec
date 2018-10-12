# All tests in this file exercise resources that use the file() resource under the hood.

# Correct behavior is for every one of these tests to fail.
control 'fail_file_based' do
  describe aide_conf('/no/such/path') do
    its('selection_lines') { should_not include 'telnet' }
  end
end
