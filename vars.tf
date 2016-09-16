#Database configuration

variable "db_name" {}
variable "db_host" {}
variable "db_port" {}
variable "db_username" {}
variable "db_password" {}

#Aws account and ssh keys

variable "access_key" {}
variable "secret_key" {}
variable "key_name" {}
variable "public_key_path" {}
variable "private_key_path" {}

#Ec2 variables 

variable "ec2_name" {}
variable "ec2_type" {}
variable "ec2_count" {}
variable "aws_region" {}

#Network: vpc,elb,ig and security group
variable "vpc_name" {}
variable "subnet_name" {}
variable "instance_sg_name" {}
variable "instance_sg_desc" {}
variable "elb_name" {}
variable "igw_name" {}
variable "elb_sg_name" {}
variable "elb_sg_desc" {}


#Ami configuration 
variable "aws_amis" {
  default = {
    us-west-2 = "ami-d732f0b7"
  }
}