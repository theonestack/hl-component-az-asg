require 'yaml'

describe 'compiled component az-asg' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/max_azs.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/max_azs/az-asg.compiled.yaml") }
  
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
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-az-asg"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
    end
    
    context "InstanceRole" do
      let(:resource) { template["Resources"]["InstanceRole"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"ec2.amazonaws.com"}, "Action"=>"sts:AssumeRole"}, {"Effect"=>"Allow", "Principal"=>{"Service"=>"ssm.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"ec2-describe", "PolicyDocument"=>{"Statement"=>[{"Sid"=>"ec2describe", "Action"=>["ec2:Describe*"], "Resource"=>["*"], "Effect"=>"Allow"}]}}])
      end
      
    end
    
    context "InstanceProfile" do
      let(:resource) { template["Resources"]["InstanceProfile"] }

      it "is of type AWS::IAM::InstanceProfile" do
          expect(resource["Type"]).to eq("AWS::IAM::InstanceProfile")
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Roles" do
          expect(resource["Properties"]["Roles"]).to eq([{"Ref"=>"InstanceRole"}])
      end
      
    end
    
    context "LaunchTemplate0" do
      let(:resource) { template["Resources"]["LaunchTemplate0"] }

      it "is of type AWS::EC2::LaunchTemplate" do
          expect(resource["Type"]).to eq("AWS::EC2::LaunchTemplate")
      end
      
      it "to have property LaunchTemplateData" do
          expect(resource["Properties"]["LaunchTemplateData"]).to eq({"SecurityGroupIds"=>[{"Ref"=>"SecurityGroup"}], "TagSpecifications"=>[{"ResourceType"=>"instance", "Tags"=>[{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-az-asg"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}, {"Key"=>"Role", "Value"=>{"Fn::Sub"=>"${RoleName}"}}, {"Key"=>"Name", "Value"=>{"Fn::Sub"=>["${EnvironmentName}-az-asg-${AZ}", {"AZ"=>{"Fn::Select"=>[0, {"Fn::GetAZs"=>{"Ref"=>"AWS::Region"}}]}}]}}]}, {"ResourceType"=>"volume", "Tags"=>[{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-az-asg"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}, {"Key"=>"Role", "Value"=>{"Fn::Sub"=>"${RoleName}"}}, {"Key"=>"Name", "Value"=>{"Fn::Sub"=>["${EnvironmentName}-az-asg-${AZ}", {"AZ"=>{"Fn::Select"=>[0, {"Fn::GetAZs"=>{"Ref"=>"AWS::Region"}}]}}]}}]}], "UserData"=>{"Fn::Base64"=>{"Fn::Sub"=>["#!/bin/bash\nhostname ${EnvironmentName}-${RoleName}-`/opt/aws/bin/ec2-metadata --instance-id|/usr/bin/awk '{print $2}'`\nsed '/HOSTNAME/d' /etc/sysconfig/network > /tmp/network && mv -f /tmp/network /etc/sysconfig/network && echo \"HOSTNAME=${EnvironmentName}-`/opt/aws/bin/ec2-metadata --instance-id|/usr/bin/awk '{print $2}'`\" >>/etc/sysconfig/network && /etc/init.d/network restart\ncfn-signal -e $? --region ${AWS::Region} --stack ${AWS::StackName} --resource AutoScaleGroup${AZId}\n", {"AZId"=>0}]}}, "IamInstanceProfile"=>{"Name"=>{"Ref"=>"InstanceProfile"}}, "KeyName"=>{"Fn::If"=>["KeyPairSet", {"Ref"=>"KeyPair"}, {"Ref"=>"AWS::NoValue"}]}, "ImageId"=>{"Ref"=>"Ami"}, "InstanceType"=>{"Ref"=>"InstanceType"}, "InstanceMarketOptions"=>{"Fn::If"=>["SpotEnabled", {"MarketType"=>"spot", "SpotOptions"=>{"SpotInstanceType"=>"one-time"}}, {"Ref"=>"AWS::NoValue"}]}})
      end
      
    end
    
    context "AutoScaleGroup0" do
      let(:resource) { template["Resources"]["AutoScaleGroup0"] }

      it "is of type AWS::AutoScaling::AutoScalingGroup" do
          expect(resource["Type"]).to eq("AWS::AutoScaling::AutoScalingGroup")
      end
      
      it "to have property DesiredCapacity" do
          expect(resource["Properties"]["DesiredCapacity"]).to eq({"Ref"=>"AsgDesired"})
      end
      
      it "to have property MinSize" do
          expect(resource["Properties"]["MinSize"]).to eq({"Ref"=>"AsgMin"})
      end
      
      it "to have property MaxSize" do
          expect(resource["Properties"]["MaxSize"]).to eq({"Ref"=>"AsgMax"})
      end
      
      it "to have property VPCZoneIdentifier" do
          expect(resource["Properties"]["VPCZoneIdentifier"]).to eq({"Ref"=>"SubnetIds"})
      end
      
      it "to have property LaunchTemplate" do
          expect(resource["Properties"]["LaunchTemplate"]).to eq({"LaunchTemplateId"=>{"Ref"=>"LaunchTemplate0"}, "Version"=>{"Fn::GetAtt"=>["LaunchTemplate0", "LatestVersionNumber"]}})
      end
      
      it "to have property HealthCheckGracePeriod" do
          expect(resource["Properties"]["HealthCheckGracePeriod"]).to eq({"Ref"=>"HealthCheckGracePeriod"})
      end
      
      it "to have property HealthCheckType" do
          expect(resource["Properties"]["HealthCheckType"]).to eq({"Ref"=>"HealthCheckType"})
      end
      
      it "to have property TerminationPolicies" do
          expect(resource["Properties"]["TerminationPolicies"]).to eq(["Default"])
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-az-asg"}, "PropagateAtLaunch"=>false}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}, "PropagateAtLaunch"=>false}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}, "PropagateAtLaunch"=>false}])
      end
      
    end
    
  end

end