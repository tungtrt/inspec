require 'forwardable'
require 'singleton'
require 'inspec/objects/attribute'

module Inspec

  # The AttributeRegistry's responsibilities include:
  #   - maintaining a list of Attribute objects that are bound to profiles
  #   - assisting in the lookup and creation of Attributes
  #   - being the Activation Point for AttributeProvider plugins
  #   - resolving ties between attribute providers
  class AttributeRegistry
    include Singleton
    extend Forwardable

    attr_reader :attributes_by_profile
    def_delegator :attributes_by_profile, :each
    def_delegator :attributes_by_profile, :[]
    def_delegator :attributes_by_profile, :key?, :profile_known?
    def_delegator :attributes_by_profile, :select

    def initialize
      # Keyed on String profile_name => Hash of String attribute_name => Attribute object
      @attributes_by_profile = {}

      # this is a list of optional profile name overrides set in the inspec.yml
      @profile_aliases = {}

      @plugin_registry = Inspec::Plugin::V2::Registry.instance
    end

    #-------------------------------------------------------------#
    #                 Support for Profiles
    #-------------------------------------------------------------#

    def register_profile_alias(name, alias_name)
      @profile_aliases[name] = alias_name
    end

    def list_attributes_for_profile(profile)
      attributes_by_profile[profile] = {} unless profile_known?(profile)
      attributes_by_profile[profile]
    end

    # Register any attributes that originate from outside of the profile files
    def register_external_attributes(profile_name, data = {})
      attributes_by_profile[profile_name] ||= {}

      # In a more perfect world, we could let the plugins choose
      # more of what to do; but as-is, the APIs that call this
      # are a bit over-constrained.
      # register_runner_api_attributes(profile_name, data[:runner_opts][:runner_conf][:attributes])
      register_cli_option_attributes(profile_name, data[:runner_opts][:runner_conf])
      # register_metadata_attributes(profile_name, data[:metadata])
    end

    #-------------------------------------------------------------#
    #              Support for Individual Attributes
    #-------------------------------------------------------------#
    def find_or_define_attribute(name, profile, options = {})
      profile = @profile_aliases[profile] if !profile_known?(profile) && @profile_aliases[profile]
      attributes_by_profile[profile] ||= {}
      if attributes_by_profile[profile].key?(name)
        # It may be that the attribute has been previously defined, but this call
        # is setting a value or default value
        attributes_by_profile[profile][name].update(options)
      else
        # If it doesn't already exist, but we are being called with profile data,
        # that means we're being called by the control_eval provider, which sets
        # the provenance.
        attributes_by_profile[profile][name] = Inspec::Attribute.new(name, options)
      end
      attributes_by_profile[profile][name]
    end

    alias register_attribute find_or_define_attribute

    def find_attribute(name, profile)
      profile = @profile_aliases[profile] if !profile_known?(profile) && @profile_aliases[profile]

      unless attributes_by_profile[profile].key?(name)
        error = Inspec::AttributeRegistry::AttributeError.new
        error.attribute_name = name
        error.profile_name = profile
        raise error, "Profile '#{error.profile_name}' does not have an attribute with name '#{error.attribute_name}'"
      end
      attributes_by_profile[profile][name]
    end

    #-------------------------------------------------------------#
    #               Support for Attribute Providers
    #-------------------------------------------------------------#
    def provider_activators
      plugin_registry = Inspec::Plugin::V2::Registry.instance
      plugin_registry.find_activators(plugin_type: :attribute_provider)
    end

    def activated_provider_classes
      providers.select(&:activated?).map(&:implementation_class)
    end

    # TODO
    # def determine_provider_for_attribute(profile_name, attr_name, attr_options)
    #   # Take poll among already activated providers
    #   votes = activated_provider_classes.map do |klass|
    #     [ klass.assess_interest_in_attribute(attr_name, attr_options), klass ]
    #   end

    #   __debug_provider_voting('prior activation pass', attr_name, votes)

    #   # If nothing was at least 50% interested, activate all providers and re-vote
    #   unless all_providers_activated? || votes.sort { |a,b| a[0] <=> b[0] }.first.first > 50
    #     activate_all_providers!
    #     votes = activated_provider_classes.map do |klass|
    #       [klass.assess_interest_in_unbound_attribute(attr_name, attr_options), klass]
    #     end
    #     __debug_provider_voting('all activation pass', attr_name, votes)
    #   end

    #   selected_class = votes.sort { |a,b| a[0] <=> b[0] }.first

    #   selected_class.annotate_attribute_options(attr_name, attr_options)
    # end

    #-------------------------------------------------------------#
    #                  Bulk Attribute Initialization
    #-------------------------------------------------------------#

    private

    def register_runner_api_attributes(profile_name, attribute_hash)
      return if attribute_hash.nil?
      return if attribute_hash.empty?
      # These attributes all came from the Runner API.
      plugin = @plugin_registry.find_activator(plugin_type: :attribute_provider, activator_name: :runner_api)
      plugin.activate
      plugin = plugin.implementation_class

      # TODO - move this into the plugin, this is not Runner's business
      # These arrive as a bare hash - values are raw values, not options
      attribute_hash.each do |attr_name, attr_value|
        attr_options = { default: attr_value }
        plugin.annotate_attribute_options(attr_name, attr_options)
        register_attribute(attr_name, profile_name, attr_options)
      end
    end

    def register_cli_option_attributes(profile_name, runner_opts)
      # This is currently hardcoded to work with --attrs
      return unless runner_opts.key? :attrs
      plugin = @plugin_registry.find_activator(plugin_type: :attribute_provider, activator_name: :attr_file)
      plugin.activate
      plugin = plugin.implementation_class

      runner_opts[:attrs].each do |path|
        # Custom API for this purpose
        plugin.load_attribute_file(profile_name, path)
      end
    end

    # from profile.rb
    # def register_metadata_attributes
    #   if metadata.params.key?(:attributes) && metadata.params[:attributes].is_a?(Array)
    #     metadata.params[:attributes].each do |attribute|
    #       attr_options = attribute.dup
    #       name = attr_options.delete(:name)
    #       attr_options[:provenance] = {
    #         provider: :metadata,
    #         profile: metadata.params[:name],
    #         file: 'inspec.yml',
    #       }
    #       @runner_context.register_attribute(name, attr_options)
    #     end
    #   elsif metadata.params.key?(:attributes)
    #     Inspec::Log.warn 'Attributes must be defined as an Array. Skipping current definition.'
    #   end
    # end

    #-------------------------------------------------------------#
    #               Other Support
    #-------------------------------------------------------------#

    # Used in testing
    def __reset
      @attributes_by_profile = {}
      @profile_aliases = {}
      @unbound_attributes = {}
    end

    # These class methods are convenience methods so you don't always
    # have to call #instance when calling the registry
    [
      :find_or_define_attribute,
      :find_attribute,
      :register_attribute,
      :register_profile_alias,
      :list_attributes_for_profile,
      :register_unbound_attribute, # TODO: remove
      :register_external_attributes,
    ].each do |meth|
      self.define_singleton_method(meth) do |*args|
        instance.send(meth, *args)
      end
    end
  end
end
