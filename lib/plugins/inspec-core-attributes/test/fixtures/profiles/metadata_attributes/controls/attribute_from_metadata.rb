attribute('basic_embedded', default: 'basic_from_embedded')

control 'basic-pass' do
  # Should still be able to read a control-embedded attribute
  describe atribute('basic_embedded') do
   it { should cmp 'basic_from_embedded' }
  end

  # Should be able to read a metadata-embedded attribute
  describe atribute('basic_from_metadata') do
    it { should cmp 'basic_from_metadata' }
   end
end

control 'basic-fail' do
  # Should be able to handle a miss
end

control 'back-compat'
  # Back-compat
  # Should be able to read an attribute that was set using the 'default' key
end

control 'data-typing'
  # YAML parser checks:
  #   These verify that we can read deep typed structures out of YAML.
  #   Not intended to exercise the Inspec Attribute type validator system.

  # Should be able to read a number - int
  # Should be able to read a number - decimal
  # Should be able to read a boolean
  # Should be able to read an array

  # Should be able to read an hash
  describe 'test the hash_valued attribute set in metadata_attributes/inspec.yml' do
    subject { attribute('hash_valued') }
    check_hash = { a: true, b: false, c: '123' }
    it { should cmp check_hash }
  end
  
  # Should be able to read a deep structure
end

# describe 'test the val_string attribute set in the global inspec.yml' do
#   subject { attribute('val_string') }
#   it { should cmp 'test-attr' }
# end

# describe 'test the val_numeric attribute set in the global inspec.yml' do
#   subject { attribute('val_numeric') }
#   it { should cmp 443 }
# end

# describe 'test the val_boolean attribute set in the global inspec.yml' do
#   subject { attribute('val_boolean') }
#   it { should cmp true }
# end

# describe 'test the val_regex attribute set in the global inspec.yml' do
#   subject { attribute('val_regex') }
#   it { should cmp '/^\d*/'}
# end

# describe 'test the val_array attribute set in the global inspec.yml' do
#   subject { attribute('val_array') }
#   check_array = [ 'a', 'b', 'c' ]
#   it { should cmp check_array }
# end



# describe 'test attribute when no default or value is set' do
#   subject { attribute('val_no_default').respond_to?(:fake_method) }
#   it { should cmp true }
# end

# describe 'test attribute with no defualt but has type' do
#   subject { attribute('val_no_default_with_type').respond_to?(:fake_method) }
#   it { should cmp true }
# end

# empty_hash_attribute = attribute('val_with_empty_hash_default', {})
# describe 'test attribute with default as empty hash' do
#   subject { empty_hash_attribute }
#   it { should cmp 'success' }
# end
