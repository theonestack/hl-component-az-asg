require 'yaml'
require 'spec_helper'

describe 'compiled component' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/default.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/default/az-asg.compiled.yaml") }

  context 'Resource InstanceRole' do

    let(:type) { template["Resources"]["InstanceRole"]["Type"] }

    it 'is of type AWS::IAM::Role' do
      expect(type).to eq('AWS::IAM::Role')
    end

  end

  context 'Resource InstanceProfile' do

    let(:type) { template["Resources"]["InstanceProfile"]["Type"] }

    it 'is of type AWS::IAM::Role' do
      expect(type).to eq('AWS::IAM::InstanceProfile')
    end

  end

end
