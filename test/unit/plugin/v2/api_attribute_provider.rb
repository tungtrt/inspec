require 'minitest/autorun'
require 'minitest/test'
require 'byebug'

require_relative '../../../../lib/inspec/plugin/v2'

class AttributeProviderSuperclassTests < MiniTest::Test
  # you can call Inspec.plugin(2, :attribute_provider) and get the plugin base class
  def test_calling_Inspec_dot_plugin_with_attribute_returns_the_attribute_base_class
    klass = Inspec.plugin(2, :attribute_provider)
    assert_kind_of Class, klass
    assert_equal 'Inspec::Plugin::V2::PluginType::AttributeProvider', klass.name
  end

  def test_plugin_type_base_classes_can_be_accessed_by_name
    klass = Inspec::Plugin::V2::PluginBase.base_class_for_type(:attribute_provider)
    assert_kind_of Class, klass
    assert_equal 'Inspec::Plugin::V2::PluginType::AttributeProvider', klass.name
  end

  def test_plugin_type_registers_an_activation_dsl_method
    klass = Inspec::Plugin::V2::PluginBase
    assert_respond_to klass, :attribute_provider, 'Activation method for attribute_provider'
  end
end

class AttributeProviderPluginV2API < MiniTest::Test
  def test_attribute_provider_api_methods_present
    # instance methods
    [
      :fetch_value,
    ].each do |method_name|
      klass = Inspec::Plugin::V2::PluginType::AttributeProvider
      assert klass.method_defined?(method_name), "AttributeProvider api instance method: #{method_name}"
    end
  end
end
