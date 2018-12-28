# encoding: utf-8

require 'helper'
require 'byebug'
require 'inspec/attribute_registry'

describe Inspec::AttributeRegistry do
  let(:attr_registry) { Inspec::AttributeRegistry }

  def setup
    Inspec::AttributeRegistry.instance.__reset
  end

  let(:event_10) do
    Inspec::Attribute::Event.new(
      provider: :test_harness,
      priority: 10,
      profile: 'dummy_profile',
      value: attr_value,
      file: __FILE__,
    )
  end

  let(:event_10_no_value) do
    Inspec::Attribute::Event.new(
      provider: :test_harness,
      priority: 10,
      profile: 'dummy_profile',
      file: __FILE__,
    )
  end

  describe 'creating a profile attribute' do
    describe 'when the value is missing' do
      it 'creates an attribute without a value' do
        attr_registry.register_attribute('test_attribute', 'dummy_profile', event: event_10_no_value)
        # confirm we get the dummy default
        attr_registry.find_attribute('test_attribute', 'dummy_profile').value.class.must_equal Inspec::Attribute::DEFAULT_ATTRIBUTE
      end
    end

    describe 'when the value is provided as a default' do
      let(:attr_value) { 'silver' }
      it 'creates an attribute with a default value' do
        attr_registry.register_attribute('color', 'dummy_profile', default: 'silver', event: event_10)
        attr_registry.find_attribute('color', 'dummy_profile').value.must_equal 'silver'
      end
    end
  end

  describe 'creating a profile with a name alias' do
    describe 'when the value is provided as a default' do
      let(:attr_value) { 'blue' }
      it 'creates a default attribute on a profile with an alias' do
        attr_registry.register_profile_alias('old_profile', 'new_profile')
        attr_registry.register_attribute('color', 'new_profile', default: 'blue', event: event_10)
        attr_registry.find_attribute('color', 'new_profile').value.must_equal 'blue'
        attr_registry.find_attribute('color', 'old_profile').value.must_equal 'blue'
      end
    end
  end

  describe 'creating a profile and listing the attrs' do
    let(:attr_value) { 'blue' }
    it 'creates a profile with attr_registry' do
      attr_registry.register_attribute('color', 'dummy_profile', default: 'silver', event: event_10)
      attr_registry.register_attribute('color2', 'dummy_profile', default: 'blue', event: event_10)
      attr_registry.register_attribute('color3', 'dummy_profile', default: 'green', event: event_10)
      attr_registry.list_attributes_for_profile('dummy_profile').size.must_equal 3
    end
  end

  describe 'validate the correct objects are getting created' do
    let(:attr_value) { 'silver' }
    it 'creates a profile with attr_registry' do
      attr_registry.register_attribute('color', 'dummy_profile', default: 'silver', event: event_10).class.must_equal Inspec::Attribute
      attr_registry.list_attributes_for_profile('dummy_profile').size.must_equal 1
    end
  end

  describe 'validate find_attribute method' do
    describe 'when the attribute does exist' do
      let(:attr_value) { 'silver' }
      it 'find an attribute which exist' do
        attribute = attr_registry.register_attribute('color', 'dummy_profile', event: event_10)
        attr_registry.find_attribute('color', 'dummy_profile').value.must_equal 'silver'
      end
    end

    describe 'when the attribute does not exist' do
      let(:attr_value) { 'silver' }
      it 'errors when trying to find an unknown attribute on a known profile' do
        attribute = attr_registry.register_attribute('color', 'dummy_profile', event: event_10)
        ex = assert_raises(Inspec::AttributeRegistry::AttributeError) { attr_registry.find_attribute('unknown_attribute', 'dummy_profile') }
        ex.message.must_match "Profile 'dummy_profile' does not have an attribute with name 'unknown_attribute'"
      end
    end
  end
end
