# Access Details
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.aws_region}"
}


# VPC
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  tags {
        Name = "${var.vpc_name}"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
    tags {
        Name = "${var.igw_name}"
    }
}

# VPC internet access
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Subnet
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
    tags {
        Name = "${var.subnet_name}"
    }
}

# Security Group ELB
resource "aws_security_group" "elb" {
  name        = "${var.elb_sg_name}"
  description = "${var.elb_sg_desc}"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group instance
resource "aws_security_group" "default" {
  name        = "${var.instance_sg_name}"
  description = "${var.instance_sg_desc}"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "${var.elb_name}"

  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

}


#SSH KEY
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "web" {
    key_name = "${aws_key_pair.auth.id}"
    count = "${var.ec2_count}"
    instance_type = "${var.ec2_type}"
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    vpc_security_group_ids = ["${aws_security_group.default.id}"]
    subnet_id = "${aws_subnet.default.id}"
    connection {
      user = "ubuntu"
      type = "ssh"
      private_key = "${file(var.private_key_path)}"
    }
      tags {
        Name = "${var.ec2_name}-${count.index}"
    }


  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install apt-transport-https ca-certificates",
      "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D",
      "echo deb https://apt.dockerproject.org/repo ubuntu-trusty main | sudo tee -a /etc/apt/sources.list.d/docker.list",
      "sudo apt-get update",
      "sudo apt-get install -y docker-engine",
      "sudo docker run --name wordpress --restart=always -d -p 80:80 -e WORDPRESS_DB_NAME=${var.db_name} -e WORDPRESS_DB_HOST=${var.db_host}:${var.db_port} -e WORDPRESS_DB_USER=${var.db_username} -e WORDPRESS_DB_PASSWORD=${var.db_password} wordpress"
    ]
  }
}

output "url" {
  value = "${aws_elb.web.dns_name}"
}