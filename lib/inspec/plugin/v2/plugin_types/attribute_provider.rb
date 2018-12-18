module Inspec::Plugin::V2::PluginType
  class AttributeProvider < Inspec::Plugin::V2::PluginBase
    register_plugin_type :attribute_provider

    # Retrieve a value from an attribute provider.
    def fetch_value(attribute_name, profile_name = nil, opts = {})
      raise NotImplemenedError "Attribute Provider plugin classes must implement fetch_value() - #{self}"
    end

    # An existing attribute has been referenced by this provider.  
    # Add information about the history of any value change.
    def annotate_attribute_options(attr_name, attr_options = {})
      raise NotImplemenedError "Attribute Provider plugin classes must implement annotate_attribute_options() - #{self}"
    end

    # Return a number 0-100 indicating interest in servicing
    # the proposed attribute.  Higher numbers win.
    def priority_for_attribute(attr_name, profile_name)
      raise NotImplemenedError "Attribute Provider plugin classes must implement priority_for_attribute - #{self}"
    end

  end
end

