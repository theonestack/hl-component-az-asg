require 'yaml'

describe 'compiled component az-asg' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/security_group_rules.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/security_group_rules/az-asg.compiled.yaml") }
  
  context "Resource" do

    context "SecurityGroup" do
      let(:resource) { template["Resources"]["SecurityGroup"] }

      it "is of type AWS::EC2::SecurityGroup" do
          expect(resource["Type"]).to eq("AWS::EC2::SecurityGroup")
      end
      
      it "to have property VpcId" do
          expect(resource["Properties"]["VpcId"]).to eq({"Ref"=>"VPCId"})
      end
      
      it "to have property GroupDescription" do
          expect(resource["Properties"]["GroupDescription"]).to eq({"Fn::Sub"=>"${EnvironmentName} az-asg"})
      end
      
      it "to have property SecurityGroupIngress" do
          expect(resource["Properties"]["SecurityGroupIngress"]).to eq([{"FromPort"=>8080, "IpProtocol"=>"TCP", "ToPort"=>8080, "Description"=>{"Fn::Sub"=>"ingress from loadbalancer"}, "CidrIp"=>{"Fn::Sub"=>"10.0.0.0/8"}}])
      end
      
      it "to have property SecurityGroupEgress" do
          expect(resource["Properties"]["SecurityGroupEgress"]).to eq([{"FromPort"=>443, "IpProtocol"=>"TCP", "ToPort"=>443, "Description"=>{"Fn::Sub"=>"outbound https calls to external sources"}, "CidrIp"=>{"Fn::Sub"=>"0.0.0.0/0"}}, {"FromPort"=>49152, "IpProtocol"=>"TCP", "ToPort"=>65535, "Description"=>{"Fn::Sub"=>"outbound range for ephemeral ports"}, "CidrIp"=>{"Fn::Sub"=>"0.0.0.0/0"}}])
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-az-asg"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
    end
    
  end

end