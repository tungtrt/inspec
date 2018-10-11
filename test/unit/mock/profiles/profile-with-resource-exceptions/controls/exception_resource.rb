# encoding: utf-8

# checks[0]
describe exception_resource_test('should raise ResourceSkipped', :skip_me) do
  its('value') { should eq 'does not matter' }
end

# checks[1]
describe exception_resource_test('should raise ResourceFailed', :fail_me) do
  its('value') { should eq 'does not matter' }
end

# checks[2]
describe exception_resource_test('should raise ResourceUnableToRun', :unable_me) do
  its('value') { should eq 'does not matter' }
end

# checks[3]
describe exception_resource_test('should pass') do
  its('value') { should eq 'should pass' }
end

# checks[4]
describe exception_resource_test('fail inside matcher') do
  its('inside_matcher') { should eq 'does not matter' }
end

# checks[5]
describe exception_resource_test('skip inside matcher') do
  its('inside_matcher') { should eq 'does not matter' }
end

# checks[6]
describe exception_resource_test('unable inside matcher') do
  its('inside_matcher') { should eq 'does not matter' }
end

control 'should-work-within-control' do
  # checks[7][0]
  describe exception_resource_test('should skip', :skip_me) do
    its('value') { should eq 'does not matter' }
  end

  # checks[7][1]
  describe exception_resource_test('should fail', :fail_me) do
    its('value') { should eq 'does not matter' }
  end

  # checks[7][2]
  describe exception_resource_test('should unable', :unable_me) do
    its('value') { should eq 'does not matter' }
  end
end

# checks[8]
describe exception_resource_test('skip_me').matters('does not matter') do
  its('matters') { should eq 'does not matter' }
end

# checks[9]
describe exception_resource_test('fail_me').matters('does not matter') do
  its('matters') { should eq 'does not matter' }
end

# checks[10]
describe exception_resource_test('unable_me').matters('does not matter') do
  its('matters') { should eq 'does not matter' }
end

# checks[11]
describe exception_resource_test('skip_me').matters('it really does').another_filter('example') do
  its('value') { should cmp 'does not matter' }
end

# checks[12]
describe exception_resource_test('fail_me').matters('it really does').another_filter('example') do
  its('value') { should cmp 'does not matter' }
end

# checks[13]
describe exception_resource_test('unable_me').matters('it really does').another_filter('example') do
  its('value') { should cmp 'does not matter' }
end

# checks[14]
describe exception_resource_test('skip_me').matters('it really does').not_real_filter('example') do
  its('value') { should cmp 'does not matter' }
end

# checks[15]
describe exception_resource_test('fail_me').matters('it really does').not_real_filter('example') do
  its('value') { should cmp 'does not matter' }
end

# checks[16]
describe exception_resource_test('unable_me').matters('it really does').not_real_filter('example') do
  its('value') { should cmp 'does not matter' }
end

# checks[17]
describe exception_resource_test('should_pass').matters('it really does') do
  its('another_filter') { should cmp 'example' }
end

