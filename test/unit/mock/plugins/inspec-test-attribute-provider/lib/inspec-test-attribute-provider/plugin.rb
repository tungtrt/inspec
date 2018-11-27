# encoding: UTF-8
require 'inspec-test-attribute-provider/version'
module InspecPlugins
  module TestAttributeProvider
    class Plugin < ::Inspec.plugin(2)
      plugin_name :'inspec-test-attribute-provider'
      attribute_provider :test_provider_1 do
        require 'inspec-test-attribute-provider/attribute_provider_1'
        InspecPlugins::TestAttributeProvider::AttributeProvider1
      end
    end
  end
end
