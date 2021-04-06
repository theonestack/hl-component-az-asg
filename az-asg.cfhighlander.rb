CfhighlanderTemplate do
  Name 'az-asg'
  Description "ASG per AWS AZ"

  DependsOn 'lib-iam@0.1.0'
  DependsOn 'lib-ec2@0.2.1'

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true

    ComponentParam 'RoleName', component_name

    ComponentParam 'AvailabilityZones', max_availability_zones, 
      allowedValues: (1..max_availability_zones).to_a,
      description: 'Set the availability zone count for the autoscaling groups'

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
    ComponentParam 'KeyPair', ''
    ComponentParam 'Ami', type: 'AWS::EC2::Image::Id'
    ComponentParam 'SubnetIds', type: 'CommaDelimitedList'

    ComponentParam 'AsgDesired', '1'
    ComponentParam 'AsgMin', '1'
    ComponentParam 'AsgMax', '1'

    ComponentParam 'HealthCheckType', 'EC2', allowedValues: ['EC2','ELB'] 
    ComponentParam 'HealthCheckGracePeriod', '500'

    ComponentParam 'InstanceType', 't3.small'
    ComponentParam 'Spot', 'false', allowedValues: ['true','false']
  end


end
