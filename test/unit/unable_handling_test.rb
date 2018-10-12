require 'helper'
require 'inspec/exceptions'

describe 'UnableToRun exception handling' do
  describe 'exception class structure' do

    let(:base_class) { Inspec::Exceptions::ResourceUnableToRun }

    describe 'attributes of the base' do
      [
        :resource_name,
        :profile_name,
        :payload,
      ].each do |attribute|
        it "should have a #{attribute} attribute" do
          base_class.instance_methods.must_include(attribute)
        end
      end
    end
  end
end
