# This should simply not error
unless input('test-01', value: 'test-01') == 'test-01'
  raise 'Failed bare input access'
end

describe input('test-02', value: 'test-02') do
  it { should cmp 'test-02' }
end

describe 'mentioning an input in a bare describe block as a redirected subject' do
  subject { input('test-03', value: 'test-03') }
  it { should cmp 'test-03' }
end

control 'test using an input inside a control block as the describe subject' do
  describe input('test-04', value: 'test-04') do
    it { should cmp 'test-04' }
  end
end

control "test using inputs in the test its block" do
  describe 'test-05' do
    it { should cmp input('test-05', value: 'test-05') }
  end
end

control "test using inputs in a describe.one block" do
  describe.one do
    describe input('test-06', value: 'test-06') do
      it { should cmp 'test-06' }
    end
    describe 'test-07' do
      it { should cmp input('test-07', value: 'test-07') }
    end
  end
end

# TODO: add test for OR
