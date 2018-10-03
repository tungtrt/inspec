module InspecPlugins::Attr42
  class AttributeProvider
    def fetch_value(attribute_name, profile_name = nil)
      # This behavior is tightly coupled to the test fixture in
      # test/unit/mock/profiles/global_attributes
      # and the attribute_provider tests in test/functional/plugin_test.rb

      profile_name ||= 'TOPLEVEL'
      fixture = {
        'TOPLEVEL'
      }




      raise NotImplemenedError "Attribute Provider plugin classes must implement fetch_value() - #{self}"
    end
  end
end