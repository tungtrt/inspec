# encoding: utf-8
module InspecPlugins::TestAttributeProvider
  class AttributeProvider1 < Inspec.plugin(2, :attribute_provider)
    def fetch_value(attribute_name, profile_name)
      'the-value-from-the-plugin'
    end
  end
end
