# encoding:utf-8

module Inspec
  class Attribute
    attr_accessor :name
    attr_reader :trace

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

    #===========================================================================#
    #                        Class TraceEntry
    #===========================================================================#

    # Information about how the attribute obtained its value.
    # Each time it changes, a TraceEntry is added to the #trace array.
    TraceEntry = Struct.new(
      :provider,  # Name of the plugin
      :priority,  # Priority of this plugin for resolving conflicts.  1-100, higher numbers win.
      :profile,   # Profile from which the attribute was being set
      :value,     # New value, if provided.
      :file,      # File containing the attribute-changing action, if known
      :line,      # Line in file containing the attribute-changing action, if known
    )

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

    attr_reader :current_value, :default_value, :description, :identifier, :name, :title, :type_restriction

    def initialize(name, options = {})
      @name = name
      @type_restriction = options[:type]
      @required = options[:required]

      # Array of TraceEntry objeccts.  These compete with one another to determine
      # the value of the attribute when value() is called, as well as providing a
      # debugging record of when and how the value changed.
      @trace = []

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
      @required = opts[:required] if options.key?(:required)
      @identifier = options[:identifier] if options.key?(:identifier)
      @type_restriction = options[:type_restriction] if options.key?(:type_restriction)

      raise 'trace_entry is required' unless options.key?(:trace_entry)
      trace << options[:trace_entry]

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

    private
    def update_current_value!
      # Examine the proposals to determine highest-priority value (descending sort)
      proposals = trace.dup.sort { |a, b| b.priority <=> a.priority }
      winning_value = proposals.first.value
      @current_value = winning_value.nil? ? DEFAULT_ATTRIBUTE.new(name) : winning_value
    end

    #--------------------------------------------------------------------------#
    #                           Validation
    #--------------------------------------------------------------------------#

    private
    def enforce_presence_validation
      # skip if we are not doing an exec call (archive/vendor/check)
      return unless Inspec::BaseCLI.inspec_cli_command == :exec

      if current_value.nil?
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
