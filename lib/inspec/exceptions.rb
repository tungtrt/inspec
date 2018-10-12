# encoding: utf-8
# copyright: 2017, Chef Software Inc.

module Inspec
  module Exceptions
    class AttributesFileDoesNotExist < ArgumentError; end
    class AttributesFileNotReadable < ArgumentError; end
    class SecretsBackendNotFound < ArgumentError; end

    class UnexpectedResourceOutcome < StandardError
      attr_accessor :resource_name, :payload, :profile_name
    end
    class ResourceFailed < UnexpectedResourceOutcome; end
    class ResourceSkipped < UnexpectedResourceOutcome; end
    class ResourceUnableToRun < UnexpectedResourceOutcome
      def message
        'Unable to run: ' + super
      end
    end

  end
end
