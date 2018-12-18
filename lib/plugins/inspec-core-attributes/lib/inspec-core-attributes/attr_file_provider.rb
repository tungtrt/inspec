# encoding: utf-8

require 'yaml'

module InspecPlugins::CoreAttributes
  # AttrFileProvider provides support for parsing YAML files
  # specified using --attrs
  # This Attribute provider reads those YAML files, and properly
  # registers them in AttributeRegistry.

  class AttrFileProvider < Inspec.plugin(2, :attribute_provider)

    # Attributes that have values in attrfiles are relatively
    # high priority - fixed at 40/100.
    def self.priority_for_attribute(_attr_name, _profile_name)
      40
    end

    def self.load_attribute_file(profile_name, file_path)
      ensure_attribute_file_readability!(file_path)
      yaml_data = load_yaml_data!(file_path)

      attr_reg = Inspec::AttributeRegistry.instance
      yaml_data.each do |attr_name, attr_value|
        attr_reg.register_attribute(
          attr_name,
          profile_name,
          default: attr_value, # TODO: use value:, not default:
          trace_entry: Inspec::Attribute::TraceEntry.new(
            :attr_file,
            self.priority_for_attribute(attr_name, profile_name),
            profile_name,
            attr_value,
            file_path,
            # TODO: can we get line data?
          )
        )
      end
    end

    # Ensures the file is readable, or throws an exception
    def self.ensure_attribute_file_readability!(path)
      unless File.exist?(path)
        raise Inspec::Exceptions::AttributesFileDoesNotExist,
              "Cannot find attributes file '#{path}'. " \
              'Check to make sure file exists.'
      end

      unless File.readable?(path)
        raise Inspec::Exceptions::AttributesFileNotReadable,
              "Cannot read attributes file '#{path}'. " \
              'Check to make sure file is readable.'
      end
    end

    # Reads the data as a Hash, or throws an exception
    def self.load_yaml_data!(file_path)
      begin
        yaml_data = ::YAML.load_file(file_path)
      rescue => e # TODO: make this more specific
        raise "Error reading InSpec attributes: #{e}"
      end

      unless yaml_data.is_a?(Hash)
        Inspec::Log.warn("#{self} unable to parse #{file_path}: invalid YAML or contents are not a Hash")
        return
      end

      yaml_data
    end
  end
end
