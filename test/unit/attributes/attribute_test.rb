# encoding: utf-8

require 'helper'
require 'inspec/objects/attribute'

describe Inspec::Attribute do
  let(:attribute) { Inspec::Attribute.new('test_attribute') }

  #----------------------------------------------------------------------#
  #                  Setting Value using default: option
  #----------------------------------------------------------------------#

  describe 'attribute with a default value set' do
    it 'returns the user-configured default value if no value is assigned' do
      attribute = Inspec::Attribute.new('test_attribute', default: 'default_value')
      attribute.value.must_equal 'default_value'
    end

    it 'returns the user-configured default value if no value is assigned (nil)' do
      attribute = Inspec::Attribute.new('test_attribute', default: nil)
      attribute.value.must_be_nil
    end

    it 'returns the user-configured default value if no value is assigned (false)' do
      attribute = Inspec::Attribute.new('test_attribute', default: false)
      attribute.value.must_equal false
    end
  end

  #----------------------------------------------------------------------#
  #                       value=(), value()
  #----------------------------------------------------------------------#

  describe 'setting the value via the value= method' do
    it 'returns the actual value, not the default, if one is assigned' do
      attribute.value = 'new_value'
      attribute.value.must_equal 'new_value'
    end

    it 'support storing and returning false' do
      attribute.value = false
      attribute.value.must_equal false
    end

    it 'returns value if overriding the default' do
      attribute = Inspec::Attribute.new('test_attribute', default: 'default_value')
      attribute.value = 'test_value'
      attribute.value.must_equal 'test_value'
    end
  end

  #----------------------------------------------------------------------#
  #                       DEFAULT_ATTRIBUTE
  #----------------------------------------------------------------------#
  describe 'when no value is provided' do
    it 'returns the default value if no value is assigned' do
      attribute.value.must_be_kind_of Inspec::Attribute::DEFAULT_ATTRIBUTE
      attribute.value.to_s.must_equal "Attribute 'test_attribute' does not have a value. Skipping test."
    end

    it 'has a default value that can be called like a nested map' do
      attribute.value['hello']['world'][1][2]['three'].wont_be_nil
    end

    it 'has a default value that can take any nested method calls' do
      attribute.value.call.some.fancy.functions.wont_be_nil
    end
  end

  #----------------------------------------------------------------------#
  #                      `required` validation
  #----------------------------------------------------------------------#
  describe 'validate required method' do
    it 'does not error if a default is set' do
      attribute = Inspec::Attribute.new('test_attribute', default: 'default_value', required: true)
      attribute.value.must_equal 'default_value'
    end

    it 'does not error if a value is specified' do
      attribute = Inspec::Attribute.new('test_attribute', required: true)
      attribute.value = 'test_value'
      attribute.value.must_equal 'test_value'
    end

    it 'returns an error if no value is set' do
      Inspec::BaseCLI.inspec_cli_command = :exec
      attribute = Inspec::Attribute.new('test_attribute', required: true)
      ex = assert_raises(Inspec::Attribute::RequiredError) { attribute.value }
      ex.message.must_match /Attribute 'test_attribute' is required and does not have a value./
      Inspec::BaseCLI.inspec_cli_command = nil
    end
  end

  #----------------------------------------------------------------------#
  #                           type validation
  #----------------------------------------------------------------------#
  describe 'validate value type method' do
    let(:opts) { {} }
    let(:attribute) { Inspec::Attribute.new('test_attribute', opts) }

    it 'validates a string type' do
      opts[:type] = 'string'
      attribute.send(:enforce_type_validation, 'string')
    end

    it 'returns an error if a invalid string is set' do
      opts[:type] = 'string'
      ex = assert_raises(Inspec::Attribute::ValidationError) { attribute.send(:enforce_type_validation, 123) }
      ex.message.must_match /Attribute 'test_attribute' with value '123' does not validate to type 'String'./
    end

    it 'validates a numeric type' do
      opts[:type] = 'numeric'
      attribute.send(:enforce_type_validation, 123.33)
    end

    it 'returns an error if a invalid numeric is set' do
      opts[:type] = 'numeric'
      ex = assert_raises(Inspec::Attribute::ValidationError) { attribute.send(:enforce_type_validation, 'invalid') }
      ex.message.must_match /Attribute 'test_attribute' with value 'invalid' does not validate to type 'Numeric'./
    end

    it 'validates a regex type' do
      opts[:type] = 'regex'
      attribute.send(:enforce_type_validation, '/^\d*$/')
    end

    it 'returns an error if a invalid regex is set' do
      opts[:type] = 'regex'
      ex = assert_raises(Inspec::Attribute::ValidationError) { attribute.send(:enforce_type_validation, '/(.+/') }
      ex.message.must_match "Attribute 'test_attribute' with value '/(.+/' does not validate to type 'Regexp'."
    end

    it 'validates a array type' do
      opts[:type] = 'Array'
      value = [1, 2, 3]
      attribute.send(:enforce_type_validation, value)
    end

    it 'returns an error if a invalid array is set' do
      opts[:type] = 'Array'
      value = { a: 1, b: 2, c: 3 }
      ex = assert_raises(Inspec::Attribute::ValidationError) { attribute.send(:enforce_type_validation, value) }
      ex.message.must_match /Attribute 'test_attribute' with value '{:a=>1, :b=>2, :c=>3}' does not validate to type 'Array'./
    end

    it 'validates a hash type' do
      opts[:type] = 'Hash'
      value = { a: 1, b: 2, c: 3 }
      attribute.send(:enforce_type_validation, value)
    end

    it 'returns an error if a invalid hash is set' do
      opts[:type] = 'hash'
      ex = assert_raises(Inspec::Attribute::ValidationError) { attribute.send(:enforce_type_validation, 'invalid') }
      ex.message.must_match /Attribute 'test_attribute' with value 'invalid' does not validate to type 'Hash'./
    end

    it 'validates a boolean type' do
      opts[:type] = 'boolean'
      attribute.send(:enforce_type_validation, false)
      attribute.send(:enforce_type_validation, true)
    end

    it 'returns an error if a invalid boolean is set' do
      opts[:type] = 'boolean'
      ex = assert_raises(Inspec::Attribute::ValidationError) { attribute.send(:enforce_type_validation, 'not_true') }
      ex.message.must_match /Attribute 'test_attribute' with value 'not_true' does not validate to type 'Boolean'./
    end

    it 'validates a any type' do
      opts[:type] = 'any'
      attribute.send(:enforce_type_validation, false)
      attribute.send(:enforce_type_validation, true)
      attribute.send(:enforce_type_validation, 1)
      attribute.send(:enforce_type_validation, 'bob')
    end
  end

  #----------------------------------------------------------------------#
  #                     Limiting type vocabulary
  #----------------------------------------------------------------------#
  describe 'validate type method' do
    it 'converts regex to Regexp' do
      attribute.send(:validate_type, 'regex').must_equal 'Regexp'
    end

    it 'returns the same value if there is nothing to clean' do
      attribute.send(:validate_type, 'String').must_equal 'String'
    end

    it 'returns an error if a invalid type is sent' do
      ex = assert_raises(Inspec::Attribute::TypeError) { attribute.send(:validate_type, 'dressing') }
      ex.message.must_match /Type 'Dressing' is not a valid attribute type./
    end
  end

  describe 'valid_regexp? method' do
    it 'validates a string regex' do
      attribute.send(:valid_regexp?, '/.*/').must_equal true
    end

    it 'validates a slash regex' do
      attribute.send(:valid_regexp?, /.*/).must_equal true
    end

    it 'does not vaildate a invalid regex' do
      attribute.send(:valid_regexp?, '/.*(/').must_equal false
    end
  end

  describe 'valid_numeric? method' do
    it 'validates a string number' do
      attribute.send(:valid_numeric?, '123').must_equal true
    end

    it 'validates a float number' do
      attribute.send(:valid_numeric?, 44.55).must_equal true
    end

    it 'validats a wrong padded number' do
      attribute.send(:valid_numeric?, '00080').must_equal true
    end

    it 'does not vaildate a invalid number' do
      attribute.send(:valid_numeric?, '55.55.55.5').must_equal false
    end

    it 'does not vaildate a invalid string' do
      attribute.send(:valid_numeric?, 'one').must_equal false
    end

    it 'does not vaildate a fraction' do
      attribute.send(:valid_numeric?, '1/2').must_equal false
    end
  end
end


#----------------------------------------------------------------------#
#               Determining Value via Trace Entries
#----------------------------------------------------------------------#
