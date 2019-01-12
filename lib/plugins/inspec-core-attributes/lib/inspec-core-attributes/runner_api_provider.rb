# encoding: utf-8

require 'inspec/resource'

module InspecPlugins::CoreAttributes
  # RunnerApiProvider provides support for embedded inspec consumers,
  # such as the audit-cookbook and kitchen-inspec.
  #
  # These consumers will call Inspec::Runner.new(..., attributes: { key1: val1, key2: val2})
  # This Attribute provider reads those Hashes, and properly
  # registers them in AttributeRegistry.
  #
  class RunnerApiProvider < Inspec.plugin(2, :attribute_provider)

    # Only implement the annotator.
    def annotate_attribute_options(attr_name, attr_options)
      # Use the call stack to add provenance data.

    end
  end
end
