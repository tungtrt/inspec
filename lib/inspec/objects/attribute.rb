# encoding:utf-8

module Inspec
  class Attribute

    VALID_TYPES = %w{
      String
      Numeric
      Regexp
      Array
      Hash
      Boolean
      Any
    }.freeze

    # If you call `attribute` in a control file, the attribute will receive this priority.
    # You can override that with a :priority option.
    DEFAULT_PRIORITY_FOR_DSL_ATTRIBUTES = 20

    # If you somehow manage to initialize an Attribute outside of the DSL,
    # AND you don't provide an Attribute:Event, this is the priority you get.
    DEFAULT_PRIORITY_FOR_UNKNOWN_CALLER = 10

    # If you directly call value=, this is the priority assigned.
    # This is teh highest priority within InSpec core; though plugins
    # are free to go higher.
    DEFAULT_PRIORITY_FOR_VALUE_SET = 60

    #===========================================================================#
    #                        Class Attribute::Event
    #===========================================================================#

    # Information about how the attribute obtained its value.
    # Each time it changes, an Attribute::Event is added to the #events array.
    class Event
      EVENT_PROPERTIES = [
        :provider, # Name of the plugin
        :priority, # Priority of this plugin for resolving conflicts.  1-100, higher numbers win.
        :profile,       # Profile from which the attribute was being set
        :value,         # New value, if provided.
        :file,          # File containing the attribute-changing action, if known
        :line,          # Line in file containing the attribute-changing action, if known
      ]

      # Value has a special handler
      EVENT_PROPERTIES.reject {|p| p == :value }.each do |prop|
        attr_accessor prop
      end

      attr_reader :value

      def initialize(properties = {})
        @value_has_been_set = false

        properties.each do |prop_name, prop_value|
          if EVENT_PROPERTIES.include? prop_name
            # OK, save the property
            self.send((prop_name.to_s + '=').to_sym, prop_value)
          else
            raise "Unrecognized property to Attribute::Event: #{prop_name}"
          end
        end
      end

      def value=(the_val)
        # Even if set to nil or false, it has indeed been set; note that fact.
        @value_has_been_set = true
        @value = the_val
      end

      def value_has_been_set?
        @value_has_been_set
      end
    end

    #===========================================================================#
    #                    Class DEFAULT_ATTRIBUTE
    #===========================================================================#

    DEFAULT_ATTRIBUTE = Class.new do
      def initialize(name)
        @name = name

        # output warn message if we are in a exec call
        Inspec::Log.warn(
          "Attribute '#{@name}' does not have a value. "\
          "Use --attrs to provide a value for '#{@name}' or specify a default  "\
          "value with `attribute('#{@name}', default: 'somedefault', ...)`.",
        ) if Inspec::BaseCLI.inspec_cli_command == :exec
      end

      def method_missing(*_)
        self
      end

      def respond_to_missing?(_, _)
        true
      end

      def to_s
        "Attribute '#{@name}' does not have a value. Skipping test."
      end
    end

    #===========================================================================#
    #                       Class Inspec::Attribute
    #===========================================================================#
    attr_accessor :name
    attr_reader :events

    attr_reader :current_value, :description, :identifier, :name, :title, :type_restriction

    def initialize(name, options = {})
      @name = name
      @type_restriction = options[:type]
      @required = options[:required]

      # Array of Attribute::Event objects.  These compete with one another to determine
      # the value of the attribute when value() is called, as well as providing a
      # debugging record of when and how the value changed.
      @events = []

      @current_value = nil  # Will be determined in determine_current_value!

      # For consistency, call update to set everything else
      update(options)
    end

    #--------------------------------------------------------------------------#
    #                      Metadata and Marshalling
    #--------------------------------------------------------------------------#

    def required?
      @required == true
    end

    def ruby_var_identifier
      identifier || 'attr_' + name.downcase.strip.gsub(/\s+/, '-').gsub(/[^\w-]/, '')
    end

    def to_hash
      opts = {}
      opts[:title] = title if title
      # TODO: deprecate use of 'default' as value-setting property
      opts[:default] = value
      opts[:description] = description if description
      opts[:required] = required? if required?
      opts[:identifier] = identifier if identifier

      {
        name: name,
        options: opts,
      }
    end

    def to_ruby
      res = ["#{ruby_var_identifier} = attribute('#{name}',{"]
      res.push "  title: '#{title}'," unless title.to_s.empty?
      # TODO: deprecate use of 'default' as value-setting property
      res.push "  default: #{value.inspect}," unless value.to_s.empty?
      res.push "  description: '#{description}'," unless description.to_s.empty?
      res.push '})'
      res.join("\n")
    end

    #--------------------------------------------------------------------------#
    #                           Managing Value
    #--------------------------------------------------------------------------#

    def update(options)
      @title = options[:title] if options.key?(:title)
      @description = options[:description] if options.key?(:description)
      @required = options[:required] if options.key?(:required)
      @identifier = options[:identifier] if options.key?(:identifier)
      @type_restriction = options[:type_restriction] if options.key?(:type_restriction)

      infer_event(options) unless options.key?(:event)
      events << options[:event]

      # TODO: deprecate use of 'default' as value-setting attribute
      if type_restriction && options.key?(:default)
        enforce_type_validation(options[:default])
      end

      update_current_value!
    end

    def value
      update_current_value!
      enforce_presence_validation if required?
      current_value
    end

    def value=(new_value, priority = DEFAULT_PRIORITY_FOR_VALUE_SET)
      enforce_type_validation(new_value)

      # Inject a new Event with the new value.
      location = caller_locations(1,1).first
      events << Event.new(
        provider: :value_setter,
        priority: priority,
        value: new_value,
        file: location.path,
        line: location.lineno,
      )

      update_current_value!
      current_value
    end

    private
    def update_current_value!
      # Examine the proposals to determine highest-priority value (descending sort)
      proposals = events.select(&:'value_has_been_set?').sort { |a, b| b.priority <=> a.priority }
      if proposals.empty?
        # No event has yet set a value (not even nil or false) - return special value
        @current_value = DEFAULT_ATTRIBUTE.new(name)
      else
        @current_value = proposals.first.value
      end
    end

    def infer_event(options)
      # This is generally used in unit testing
      # Don't rely on this working; you really should be passing a proper Attribute::Event
      # with the context information you have.
      location = caller_locations(4,1).first
      event = Attribute::Event.new(
        provider: :unknown,
        priority: options[:priority] || Inspec::Attribute::DEFAULT_PRIORITY_FOR_UNKNOWN_CALLER,
        profile: options[:profile_name] || options[:profile_id] || 'unknown',
        file: location.path,
        line: location.lineno,
      )
      # TODO: deprecate use of 'default' as value-setting property
      event.value = options[:default] if options.key?(:default)
      options[:event] = event
    end

    #--------------------------------------------------------------------------#
    #                           Validation
    #--------------------------------------------------------------------------#

    private
    def enforce_presence_validation
      # skip if we are not doing an exec call (archive/vendor/check)
      return unless Inspec::BaseCLI.inspec_cli_command == :exec

      if current_value.nil? || current_value.is_a?(DEFAULT_ATTRIBUTE)
        error = Inspec::Attribute::RequiredError.new
        error.attribute_name = name
        raise error, "Attribute '#{error.attribute_name}' is required and does not have a value."
      end
    end

    def validate_type(type)
      type = type.capitalize
      abbreviations = {
        'Num' => 'Numeric',
        'Regex' => 'Regexp',
      }
      type = abbreviations[type] if abbreviations.key?(type)
      if !VALID_TYPES.include?(type)
        error = Inspec::Attribute::TypeError.new
        error.attribute_type = type
        raise error, "Type '#{error.attribute_type}' is not a valid attribute type."
      end
      type
    end

    def valid_numeric?(value)
      Float(value)
      true
    rescue
      false
    end

    def valid_regexp?(value)
      # check for invalid regex syntex
      Regexp.new(value)
      true
    rescue
      false
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def enforce_type_validation(value)
      return unless type_restriction
      type = validate_type(type_restriction)
      return if type == 'Any'

      invalid_type = false
      if type == 'Regexp'
        invalid_type = true if !value.is_a?(String) || !valid_regexp?(value)
      elsif type == 'Numeric'
        invalid_type = true if !valid_numeric?(value)
      elsif type == 'Boolean'
        invalid_type = true if ![true, false].include?(value)
      elsif value.is_a?(Module.const_get(type)) == false
        invalid_type = true
      end

      if invalid_type == true
        error = Inspec::Attribute::ValidationError.new
        error.attribute_name = @name
        error.attribute_value = value
        error.attribute_type = type
        raise error, "Attribute '#{error.attribute_name}' with value '#{error.attribute_value}' does not validate to type '#{error.attribute_type}'."
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  end
end
