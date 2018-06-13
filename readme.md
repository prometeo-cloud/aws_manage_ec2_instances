# aws_manage_ec2_instances

## Description:

Manages AWS EC2 Instances as follows:
- Running the role will create the EC2 Instances defined in `ec2_instances` when the variable `arg_action` is not defined or is defined and set to `create`
- Running the role will delete the EC2 Instances defined in `ec2_instances` and any associated elastic IP addresses and Route Table routes when the variable `arg_action` is defined and is set to `delete` 
- Running the [ec2_instance_get_facts.yml](./tasks/ec2_instance_get_facts.yml) play will return information about the specified EC2 Instance.
- Running the [ec2_key_pair_create.yml](./tasks/ec2_key_pair_create.yml) play will create an EC2 key pair and a local PEM file.
- Running the [ec2_key_pair_delete.yml](./tasks/ec2_key_pair_delete.yml) play will delete an EC2 key pair and the local PAM file.
- Running the [ec2_authorised_user_add.yml](./tasks/ec2_authorised_user_add.yml) play will add users public key to the `authorized_keys` file.


This role requires Boto3 to be installed as follows:

`sudo pip install boto3`

or:

```yaml
- name: Install boto3
  easy_install:
    name: boto3
    state: present
```

## Dependencies

This role uses the AWS cli.  It therefore requires AWS credentials as environment variables or in a configuration file (see [here](https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#cli-aws-help-config-vars)).  The role `aws_credentials` will create a config file for use with the AWS cli.

## Behaviour:

**Feature:** Create AWS EC2 Instances  
- **Given** valid AWS credentials
- **Given** valid AWS infrastructure
- **When** the script is executed when `arg_action` is not defined or is defined and not set to `delete`
- **Then** the EC2 Instances are created in the specified VPC if they do not exist

**Feature:** Create AWS EC2 Jump Box
- **Given** valid AWS credentials
- **Given** valid AWS infrastructure
- **When** the script is executed when `arg_action` is not defined or is defined and not set to `delete`
- **When** the `ec2_instances` variable `jumpbox` is defined and set to `yes`
- **Then** the EC2 Instances are created in the specified VPC if they do not exist

**Feature:** Terminate AWS EC2 Instances  
- **Given** valid AWS credentials
- **Given** valid AWS infrastructure
- **When** the script is executed when `arg_action` is defined and is set to `delete`
- **Then** the EC2 Instances are deleted

**Feature:** Add authorised user public keys to EC2 Instance(s)
- **Given** valid AWS credentials
- **Given** valid AWS infrastructure
- **When** the playbook [ec2_authorised_user_add.yml](tasks/ec2_authorised_user_add.yml) is executed
- **Then** the users are added to the EC2 Instance `authorized_keys` file if they do not already exist

**Feature:** Remove authorised user public keys from EC2 Instance(s)
- **Given** valid AWS credentials
- **Given** valid AWS infrastructure
- **When** the playbook [ec2_authorised_user_add.yml](tasks/ec2_authorised_user_add.yml) is executed
- **Then** the users are removed from the EC2 Instance `authorized_keys` file if they already exist and their public key is not in the list


## Configuration:

Common variables used by this role:

| Variable | Description | Example |
|-----|-----|-----|
| **aws_region** | AWS region | See [AWS regions](http://docs.aws.amazon.com/general/latest/gr/rande.html#ec2_region) |
| **aws_access_key** | AWS access key | AKIAIOSFODNN7EXAMPLE |
| **aws_secret_key** | AWS secret key | wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY |
| **resource_tags** | List of resource tags | see usage |

Variables specific to this role:

| Variable | Description | Example |
|-----|-----|-----|
| **ec2_instances** | List of EC2 Instances to [create](#create-ec2-instance) or [delete](#delete-ec2-instance). | see usage |
| **ec2_instance_tag** | The `Name:` tag of the EC2 Instance to get information about. | [see usage](#get-ec2-instance-facts) |
| **key_pair_name** | Key pair name to [create](#create-ec2-key-pair) or [delete](#delete-ec2-key-pair) | see usage |
| **key_pair_region** | Region in which to [create](#create-ec2-key-pair) or [delete](#delete-ec2-key-pair) the key pair | see usage |
| **authorised_users_add** | List of user public keys to [add](#add-authorised-users) to the `authorized_keys` file | see usage |
| **authorised_users_remove** | List of user public keys to [remove](#remove-authorised-users) from the `authorized_keys` file | see usage |
| **ec2_instances.jumpbox** | When set to `yes` this will create an EC2 Instance as a Jump Box with an EIP attached to give a public IP address.  A new ssh key will be generated and the public key copied to the Ansible Control Node.  The Ansible Control Node will have an entry created in `/etc/hosts` to set the DNS name and public IP.  Any entry for the DNS name in the Ansible Control Node Ansible user's `~/.ssh/known_hosts` file will be removed.  | `yes` or omitted |
| **jumpbox_user** | Jump box user name.  Created for access to the jump box. | `jumpbox-user`|
| **ec2_instances.ansible_control_node** | When defined and set to `yes` the EC2 Instance will be set up as an Ansible Control Node. | `yes` or not defined|

## Usage:

* [Create EC2 Instance](#create-ec2-instance)
* [Delete EC2 Instance](#delete-ec2-instance)
* [Add authorised user](#add-authorised-users)
* [Remove authorised user](#remove-authorised-users)
* [Create EC2 Key Pair](#create-ec2-key-pair)
* [Delete EC2 Key Pair](#delete-ec2-key-pair)
* [Get EC2 Instance Facts](#get-ec2-instance-facts)

#### Create EC2 Instance
[[back to usage](#usage)]

How to invoke the role from a playbook (create EC2 instances):

```yaml
- name: Create AWS EC2 Instances
  include_role:
    name: "aws_manage_ec2_instances"
  vars:
    images:                           # EC2 images definitions
      base:
        ami: ami-c1d2caa5             # AMI of EC2 image
        type: t2.micro                # EC2 image type
      infra:
        ami: ami-2b9d6c52
        type: m4.large

    resource_tags:
      Name: "{{ resource_name }}"     # set by the role using the resource name
      Project: "My Project"
      Owner: "Acme Co."

    jumpbox_user: "jumpbox-access-user"

    ec2_instances:
      - name: "test-jump-box"         # name of the EC2 Instance (resource name for the Name tag)
        dns_name: "jumpbox.my-domain-name.net"  # optional - when specified will be updated in 
                                                # /etc/hosts and removed from ~/.ssh/known_hosts of Ansible user
        groups:
          - "my-group1"
          - "my-group2"
        image: "{{ images.base }}"    # use base image AMI
        instance_profile_name: "IAM_Role"  # IAM role - none if omitted
        jumpbox: "yes"                # this instance will be set up as a Jump Box
        key_pair_name: "my-key-pair"  # name of key pair to create to use to connect to instance
        monitoring: yes               # yes or no - default is no if omitted
        region: "{{ aws_region }}"    # AWS region
        type: "{{ images.base }}"     # use base image type
        subnet_tag: "TEST-CTRL-PUBLIC-A"   # Name tag of subnet for the instance
        termination_protection: "no"  # default is "yes" when omitted
        zone: "{{ aws_region }}a"     # AWS availability zone

      - name: "test-ocp-infra-lc-1"   # this instance will not have a public DNS
        groups:
          - "TEST-OCP-router"
          - "TEST-OCP-etcd"
        image: "{{ images.infra }}"   # use infra image AMI
        key_pair_name: "my-key-pair"  # name of key pair to create to use to connect to instance
        monitoring: yes
        region: "{{ aws_region }}"
        type: "{{ images.infra }}"    # use infra image type
        subnet_tag: "TEST-CTRL-PRIVATE-B"
        zone: "{{ aws_region }}b"
```

#### Delete EC2 Instance
[[back to usage](#usage)]

How to invoke the role from a playbook (delete EC2 instances):

```yaml
- name: Create AWS EC2 Instances
  include_role:
    name: "aws_ec2_ec2_instance_manage"
  vars:
    arg_action: "delete"
    ec2_instances:
      - name: "test-ocp-infra-lc-1"
        region: "{{ aws_region }}"
```

#### Add Authorised Users
[[back to usage](#usage)]

```yaml
- name: EC2 Instance Management
  include_role:
    name: aws_manage_ec2_instances
    tasks_from: ec2_authorised_user_add.yml
  vars:
    ec2_instance_name: "Test Jump Box"
    key_pair_name: "TEST_admins"
    authorised_users_add:
      - "user-1-public-key"
      - "user-2-public-key"
```

#### Remove Authorised Users
[[back to usage](#usage)]

```yaml
- name: EC2 Instance Management
  include_role:
    name: aws_manage_ec2_instances
    tasks_from: ec2_authorised_user_remove.yml
  vars:
    ec2_instance_name: "Test Jump Box"
    key_pair_name: "TEST_admins"
    authorised_users_remove:
      - "user-2-public-key"
```

#### Create EC2 Key Pair
[[back to usage](#usage)]

```yaml
- name: Create AWS EC2 Key Pair
  include_role:
    name: "aws_ec2_ec2_instance_manage"
    tasks_from: ec2_key_pair_create.yml
  vars:
    key_pair_name: "test-key-pair"
    key_pair_region: "{{ aws_region }}"
```

#### Delete EC2 Key Pair
[[back to usage](#usage)]

```yaml
- name: Delete AWS EC2 Key Pair
  include_role:
    name: "aws_ec2_ec2_instance_manage"
    tasks_from: ec2_key_pair_delete.yml
  vars:
    key_pair_name: "test-key-pair"
    key_pair_region: "{{ aws_region }}"
```

#### Get EC2 Instance Facts
[[back to usage](#usage)]

How to get information about an EC2 Instance:

```yaml
- name: Get EC2 Instance facts
  include_role:
    name: "aws_manage_ec2_instances"
    tasks_from: "ec2_instance_get_facts"
  vars:
    ec2_instance_name: "Test A"
```

This will return facts in the variable `ec2_instance_facts`.  The data returned is as follows:

```yaml
"ec2_instance_facts": {
    "changed": false, 
    "failed": false, 
    "instances": [
        {
            "ami_launch_index": 0, 
            "architecture": "x86_64", 
            "block_device_mappings": [
                {
                    "device_name": "/dev/sda1", 
                    "ebs": {
                        "attach_time": "2018-04-06T09:03:20+00:00", 
                        "delete_on_termination": true, 
                        "status": "attached", 
                        "volume_id": "vol-0f3d8bb0da29a326f"
                    }
                }
            ], 
            "client_token": "", 
            "ebs_optimized": false, 
            "ena_support": true, 
            "hypervisor": "xen", 
            "image_id": "ami-c1d2caa5", 
            "instance_id": "i-0cd57e8bf7f0b3610", 
            "instance_type": "t2.micro", 
            "launch_time": "2018-04-06T09:03:20+00:00", 
            "monitoring": {
                "state": "disabled"
            }, 
            "network_interfaces": [
                {
                    "attachment": {
                        "attach_time": "2018-04-06T09:03:20+00:00", 
                        "attachment_id": "eni-attach-be3de9dd", 
                        "delete_on_termination": true, 
                        "device_index": 0, 
                        "status": "attached"
                    }, 
                    "description": "", 
                    "groups": [
                        {
                            "group_id": "sg-beef05d5", 
                            "group_name": "TEST-Security-Group"
                        }
                    ], 
                    "ipv6_addresses": [], 
                    "mac_address": "06:9c:27:3f:d3:ea", 
                    "network_interface_id": "eni-bbd625ef", 
                    "owner_id": "121212121212", 
                    "private_dns_name": "ip-10-32-2-59.eu-west-2.compute.internal", 
                    "private_ip_address": "10.32.2.59", 
                    "private_ip_addresses": [
                        {
                            "primary": true, 
                            "private_dns_name": "ip-10-32-2-59.eu-west-2.compute.internal", 
                            "private_ip_address": "10.32.2.59"
                        }
                    ], 
                    "source_dest_check": true, 
                    "status": "in-use", 
                    "subnet_id": "subnet-7601eb0c", 
                    "vpc_id": "vpc-c9ad67a1"
                }
            ], 
            "placement": {
                "availability_zone": "eu-west-2a", 
                "group_name": "", 
                "tenancy": "default"
            }, 
            "private_dns_name": "ip-10-32-2-59.eu-west-2.compute.internal", 
            "private_ip_address": "10.32.2.59", 
            "product_codes": [], 
            "public_dns_name": "", 
            "root_device_name": "/dev/sda1", 
            "root_device_type": "ebs", 
            "security_groups": [
                {
                    "group_id": "sg-beef05d5", 
                    "group_name": "TEST-Security-Group"
                }
            ], 
            "source_dest_check": true, 
            "state": {
                "code": 16, 
                "name": "running"
            }, 
            "state_transition_reason": "", 
            "subnet_id": "subnet-7601eb0c", 
            "tags": {
                "Department": "DevOps", 
                "Implementation-Date": "2018-04-06", 
                "Name": "MY-TEST-INSTANCE-A", 
                "Owner": "Acme Co.", 
                "Project": "AWS Test"
            }, 
            "virtualization_type": "hvm", 
            "vpc_id": "vpc-c9ad67a1"
        }, 
        {
            "ami_launch_index": 0, 
            "architecture": "x86_64", 
            "block_device_mappings": [], 
            "client_token": "", 
            "ebs_optimized": false, 
            "ena_support": true, 
            "hypervisor": "xen", 
            "image_id": "ami-c1d2caa5", 
            "instance_id": "i-068a39f738bf5ad1d", 
            "instance_type": "t2.micro", 
            "launch_time": "2018-04-06T08:43:59+00:00", 
            "monitoring": {
                "state": "disabled"
            }, 
            "network_interfaces": [], 
            "placement": {
                "availability_zone": "eu-west-2a", 
                "group_name": "", 
                "tenancy": "default"
            }, 
            "private_dns_name": "", 
            "product_codes": [], 
            "public_dns_name": "", 
            "root_device_name": "/dev/sda1", 
            "root_device_type": "ebs", 
            "security_groups": [], 
            "state": {
                "code": 48, 
                "name": "terminated"
            }, 
            "state_reason": {
                "code": "Client.UserInitiatedShutdown", 
                "message": "Client.UserInitiatedShutdown: User initiated shutdown"
            }, 
            "state_transition_reason": "User initiated (2018-04-06 08:52:44 GMT)", 
            "tags": {
                "Department": "DevOps", 
                "Implementation-Date": "2018-04-06", 
                "Name": "MY-TEST-INSTANCE-A", 
                "Owner": "Acme Co.", 
                "Project": "AWS Test"
            }, 
            "virtualization_type": "hvm"
        }
    ]
}
```
