
control 'the-only-control' do
  describe 'the-only-describe' do
    subject { attribute('the-only-attribute') }
    it { should eq 'the-value-from-the-plugin' }
  end
end