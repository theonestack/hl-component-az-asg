# az-asg CfHighlander component

Creates an identical AutoScaling Group per AWS Availability Zone with a shared IAM role and security group.

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | string
| EnvironmentType | Tagging | development | true | string | ['development','production']
| RoleName | Tagging | `component_name` | false | string
| SubnetIds | comma delimited list of 2 subnets to place the directory in | | false | comma delimited list
| AvailabilityZones | Set the availability zone count for the autoscaling groups | | false | number
| VPCId | VPC Id | | false | AWS::EC2::VPC::Id
| KeyPair | Key pair for ssh access. if none is supplied the instance is launched without one | | false | string
| Ami | Amazon machine image | | false | AWS::EC2::Image::Id
| AsgDesired | the desired instance count for the ASGs | | false | number
| AsgMax | the maximum instance count for the ASGs | | false | number
| AsgMin | the minimum instance count for the ASGs | | false | number
| HealthCheckType | how the instance health is evaluated either by EC2 or ELB health checks | EC2 | false | string | ['EC2','ELB']
| HealthCheckGracePeriod | the period in seconds before a new instances health is evaluated | 500 | false | number
| InstanceType | EC2 instance type such as t3.small | t3.small | false | string
| Spot | enable spot instances on the ASG | false | false | boolean

## Configuration

### Max Availability Zones

Determines the maximum amount of availability zones this component can create an ASG for. This value is used to generate the Cloudformation conditions on the Autoscaling resources.

```yaml
max_availability_zones: 3
```

### AutoScaling Update Policy

https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html

```yaml
asg_update_policy:
  min: 0
  batch_size: 1
  suspend:
    - HealthCheck
    - ReplaceUnhealthy
    - AZRebalance
    - AlarmNotification
    - ScheduledActions
  pause_time: PT05
  wait_on_signals: 'false'
```

### IAM

to alter the asg IAM role change the following config under `iam_policies:asg:` 

```yaml
iam_policies:
  asg:
    ec2-describe:
      action:
        - ec2:Describe*
```

### Userdata

the component supports both windows and linux userdata with linux being the default.


to set it to windows alter the `operating_system:` config

```yaml
operating_system: linux #| windows

linux_user_data: |
  #!/bin/bash
  hostname ${EnvironmentName}-${RoleName}-`/opt/aws/bin/ec2-metadata --instance-id|/usr/bin/awk '{print $2}'`
  sed '/HOSTNAME/d' /etc/sysconfig/network > /tmp/network && mv -f /tmp/network /etc/sysconfig/network && echo "HOSTNAME=${EnvironmentName}-`/opt/aws/bin/ec2-metadata --instance-id|/usr/bin/awk '{print $2}'`" >>/etc/sysconfig/network && /etc/init.d/network restart

windows_user_data: |
  <powershell>
  $instanceId = invoke-restmethod -uri http://169.254.169.254/latest/meta-data/instance-id
  cfn-signal.exe -e $lastexitcode --region ${AWS::Region} --stack ${AWS::StackName} --resource 'AutoScaleGroup'
  </powershell>
```

### Termination Policy

```yaml
termination_policies:
  - Default
  # - OldestInstance
  # - NewestInstance
  # - OldestLaunchConfiguration
  # - ClosestToNextInstanceHour
```