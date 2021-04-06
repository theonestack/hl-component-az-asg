CloudFormation do

  asg_tags = []
  asg_tags.push({ Key: 'Name', Value: FnSub("${EnvironmentName}-#{component_name}") })
  asg_tags.push({ Key: 'Environment', Value: Ref(:EnvironmentName) })
  asg_tags.push({ Key: 'EnvironmentType', Value: Ref(:EnvironmentType) })
  asg_tags.push(*external_parameters.fetch(:tags, {}).map {|k,v| {Key: FnSub(k), Value: FnSub(v)}})

  Condition(:SpotEnabled, FnEquals(Ref(:Spot), 'true'))
  Condition(:KeyPairSet, FnNot(FnEquals(Ref(:KeyPair), '')))

  ip_blocks = external_parameters.fetch(:ip_blocks, {})
  security_group_rules = external_parameters.fetch(:external_parameters, {})

  EC2_SecurityGroup(:SecurityGroup) { 
    VpcId Ref(:VPCId)
    GroupDescription FnSub("${EnvironmentName} #{component_name}")
    SecurityGroupIngress generate_security_group_rules(security_group_rules['ingress'], ip_blocks, true) if security_group_rules.has_key?('ingress')
    SecurityGroupEgress generate_security_group_rules(security_group_rules['egress'], ip_blocks, false) if security_group_rules.has_key?('egress')
    Tags asg_tags
  }

  Output(:SecurityGroup) {
    Value(Ref(:SecurityGroup))
    Export FnSub("${EnvironmentName}-#{component_name}-SecurityGroup")
  }
  
  IAM_Role(:InstanceRole) {
    AssumeRolePolicyDocument service_assume_role_policy(['ec2','ssm'])
    Path '/'
    Policies iam_role_policies(external_parameters[:iam_policies]['asg'])
  }
  
  InstanceProfile(:InstanceProfile) {
    Path '/'
    Roles [Ref(:InstanceRole)]
  }
  
  external_parameters[:max_availability_zones].times do |az|
    
    get_az = { AZ: FnSelect(az, FnGetAZs(Ref('AWS::Region'))) }
    matches = ((az+1)..external_parameters[:max_availability_zones]).to_a
    
    # Determins whether we create resources in a particular availability zone
    Condition(:"CreateAvailabilityZone#{az}",
      if matches.length == 1
        FnEquals(Ref(:AvailabilityZones), external_parameters[:max_availability_zones])
      else
        FnOr(matches.map { |i| FnEquals(Ref(:AvailabilityZones), i) })
      end
    )

    operating_system = "#{external_parameters.fetch(:operating_system, 'linux')}_user_data"
    instance_userdata = external_parameters.fetch(operating_system.to_sym, 'linux')

    asg_instance_tags = asg_tags.map(&:clone)
    asg_instance_tags.push({ Key: 'Role', Value: FnSub('${RoleName}') })
    asg_instance_tags.push({ Key: 'Name', Value: FnSub("${EnvironmentName}-#{component_name}-${AZ}", get_az) })
    
    instance_tags = external_parameters.fetch(:instance_tags, {})
    asg_instance_tags.push(*instance_tags.map {|k,v| {Key: k, Value: FnSub(v)}})
    
    template_data = {
      SecurityGroupIds: [ Ref(:SecurityGroup) ],
      TagSpecifications: [
        { ResourceType: 'instance', Tags: asg_instance_tags },
        { ResourceType: 'volume', Tags: asg_instance_tags }
      ],
      UserData: FnBase64(FnSub(instance_userdata)),
      IamInstanceProfile: { Name: Ref(:InstanceProfile) },
      KeyName: FnIf(:KeyPairSet, Ref(:KeyPair), Ref('AWS::NoValue')),
      ImageId: Ref(:Ami),
      InstanceType: Ref(:InstanceType)
    }
  
    spot_options = {
      MarketType: 'spot',
      SpotOptions: {
        SpotInstanceType: 'one-time',
      }
    }
    template_data[:InstanceMarketOptions] = FnIf(:SpotEnabled, spot_options, Ref('AWS::NoValue'))
  
    volumes = external_parameters.fetch(:volumes, {})
    if volumes.any?
      template_data[:BlockDeviceMappings] = volumes
    end
      
    EC2_LaunchTemplate(:"LaunchTemplate#{az}") {
      Condition(:"CreateAvailabilityZone#{az}")
      LaunchTemplateData(template_data)
    }
  
    launch_asg_tags = asg_tags.map(&:clone)
    asg_targetgroups = []
    targetgroups = external_parameters.fetch(:targetgroups, [])
    targetgroups.each {|tg| asg_targetgroups << Ref(tg)}
    asg_update_policy = external_parameters[:asg_update_policy]
    cool_down = external_parameters.fetch(:cool_down, nil)
  
    suspend = asg_update_policy.has_key?('override_suspend') ? asg_update_policy['override_suspend'] : asg_update_policy['suspend']
   
    AutoScaling_AutoScalingGroup(:"AutoScaleGroup#{az}") {
      Condition(:"CreateAvailabilityZone#{az}")
      UpdatePolicy(:AutoScalingRollingUpdate, {
        "MinInstancesInService" => asg_update_policy['min'],
        "MaxBatchSize"          => asg_update_policy['batch_size'],
        "SuspendProcesses"      => suspend,
        "PauseTime"             => asg_update_policy['pause_time'],
        "WaitOnResourceSignals" => asg_update_policy['wait_on_signals']
      })
      UpdatePolicy(:AutoScalingScheduledAction, {
        IgnoreUnmodifiedGroupSizeProperties: true
      })
      Cooldown cool_down unless cool_down.nil?
      DesiredCapacity Ref(:AsgDesired)
      MinSize Ref(:AsgMin)
      MaxSize Ref(:AsgMax)
      VPCZoneIdentifiers Ref(:SubnetIds)
      LaunchTemplate({
        LaunchTemplateId: Ref(:"LaunchTemplate#{az}"),
        Version: FnGetAtt(:"LaunchTemplate#{az}", :LatestVersionNumber)
      })
      TargetGroupARNs asg_targetgroups if asg_targetgroups.any?
      HealthCheckGracePeriod Ref('HealthCheckGracePeriod')
      HealthCheckType Ref('HealthCheckType')
      TerminationPolicies external_parameters[:termination_policies]
      Tags launch_asg_tags.each {|tag| tag[:PropagateAtLaunch]=false}
    }
  
  end
end
