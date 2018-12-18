# encoding: UTF-8
require 'inspec-core-attributes/version'

module InspecPlugins
  module CoreAttributes
    class Plugin < ::Inspec.plugin(2)
      plugin_name :'inspec-core-attributes'

      attribute_provider :runner_api do
        # Calling this hook means the plugin should initialize, and be
        # ready to repsond to queries (though whether you authenticate /
        # connect at this point is up to you)
        require 'inspec-core-attributes/runner_api_provider'

        # Having loaded our functionality, return a class that will let the
        # attributes engine tap into it.
        InspecPlugins::CoreAttributes::RunnerApiProvider
      end

      # This handles processing of YAML files
      # specified via --attrs
      attribute_provider :attr_file do
        require 'inspec-core-attributes/attr_file_provider'
        InspecPlugins::CoreAttributes::AttrFileProvider
      end
    end
  end
end
