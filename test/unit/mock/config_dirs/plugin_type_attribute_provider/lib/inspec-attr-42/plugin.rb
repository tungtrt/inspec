module InspecPlugins
  module Attr42
    class Plugin < Inspec.plugin(2)
      plugin_name :'inspec-attr-42'
      attribute_provider :attr42 do
        require 'inspec-attr-42/attribute_provider'
        InspecPlugins::Attr42::AttributeProvider
      end
    end
  end
end