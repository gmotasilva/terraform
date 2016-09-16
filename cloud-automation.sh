#!/bin/bash


#Setup variables inputed by user
APP="$1"
ENV="$2"
EC2_COUNT="$3"
EC2_TYPE="$4"
ACTION="$5"
TERRAFORM="docker run --rm -v $(pwd):/terraform -it hashicorp/terraform:light"
ISNUMBER='^[0-9]+$'

if [ -z "$APP" ]; then
	echo "Application name is required"
	echo "usage: cloud-automation.sh <app> <environment> <server_count> <ec2_type> <action>"
	exit 2
fi

if [ -z "$ENV" ]; then
	echo "Environment is required"
	echo "usage: cloud-automation.sh <app> <environment> <server_count> <ec2_type> <action>"
	exit 2
fi

if [ -z "$EC2_COUNT" ]; then
	echo "Number of instances is required"
	echo "usage: cloud-automation.sh <app> <environment> <server_count> <ec2_type> <action>"
	exit 2
fi

if ! [[ $EC2_COUNT =~ $ISNUMBER ]]; then
	echo "Variable must be a number"
fi

if [ -z "$EC2_TYPE" ]; then
	echo "Instance size is required"
	echo "cloud-automation.sh <app> <environment> <server_count> <ec2_type> <action>"
	exit 2
fi



# Setting variables for terraform execution

key_name="GUSTAVO-MOTA-$APP-$ENV-KEYPAIR"
vpc_name="GUSTAVO-MOTA-$APP-$ENV-VPC"
igw_name="GUSTAVO-MOTA-$APP-$ENV-IGW"
subnet_name="GUSTAVO-MOTA-$APP-$ENV-SUBNET"
elb_sg_name="GUSTAVO-MOTA-$APP-$ENV-ELB-SG"
elb_sg_desc="elb secutiry group GUSTAVO-MOTA-$APP-$ENV"
instance_sg_name="GUSTAVO-MOTA-$APP-$ENV-EC2-SG"
instance_sg_desc="ec2 security group GUSTAVO-MOTA-$APP-$ENV"
elb_name="GUSTAVO-MOTA-$APP-$ENV"
ec2_type="$EC2_TYPE"
ec2_count="\"$EC2_COUNT\""
ec2_name="GUSTAVO-MOTA-$APP-$ENV"


#Execution of terraform 

echo "$ACTION action selected..." 
eval "docker run --rm -v $(pwd):/terraform -it --workdir=/terraform hashicorp/terraform:light $ACTION -var-file=config.tfvars -var 'vpc_name=$vpc_name' -var 'igw_name=$igw_name' -var 'subnet_name=$subnet_name' -var 'elb_sg_name=$elb_sg_name' -var 'elb_sg_name=$elb_sg_name' -var 'elb_sg_desc=$elb_sg_desc' -var 'instance_sg_name=$instance_sg_name' -var 'instance_sg_desc=$instance_sg_desc' -var 'elb_name=$elb_name' -var 'ec2_type=$ec2_type' -var 'key_name=$key_name' -var 'ec2_count=$ec2_count' -var 'ec2_name=$ec2_name'"
echo "Done!"
if [ "$ACTION" == "apply" ]; then
	echo -n "Elb url is: http://"
	eval "docker run --rm -v $(pwd):/terraform --workdir=/terraform -it hashicorp/terraform:light output url"
fi

if [ "$ACTION" == "destroy" ]; then
	echo -n "Provisioning destroyed"
fi
