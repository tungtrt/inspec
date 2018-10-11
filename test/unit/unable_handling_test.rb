

require 'helper'
require 'inspec/exceptions'

describe 'UnableToRun exception handling' do
  describe 'exception class structure' do

    let(:base_class) { Inspec::Exceptions::ResourceUnableToRun }

    describe 'attributes of the base' do
      it 'should have a resource name attribute' do
        base_class.instance_methods.must_include(:resource_name)
      end

      it 'should have a profile name attribute' do
        base_class.instance_methods.must_include(:profile_name)
      end
    end
  end
end

    #let(:runner) { Inspec::Runner.new({ command_runner: :generic }) }
