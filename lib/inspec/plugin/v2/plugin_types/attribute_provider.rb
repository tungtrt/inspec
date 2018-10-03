module Inspec::Plugin::V2::PluginType
  class AttributeProvider < Inspec::Plugin::V2::PluginBase
    register_plugin_type :attribute_provider

    def fetch_value(attribute_name, profile_name = nil, opts = {})
      raise NotImplemenedError "Attribute Provider plugin classes must implement fetch_value() - #{self}"
    end
  end
end

