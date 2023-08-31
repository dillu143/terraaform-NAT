terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.12"
    }
  }
}
provider "aws" {
  region     = "us-east-1"
  access_key = "give your access_key"			#give your access_key
  secret_key = "give your secret_key"	#give your secret_key
}

#vpc
resource "aws_vpc" "vpc" {                                        #creation of VPC
  cidr_block       = "10.0.0.0/31"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "VPC-demo"
  }
}

#subnet-public
resource "aws_subnet" "subnet_a" {                                  #creation of public subnet
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.1.0/30"
    map_public_ip_on_launch = "true" 		#it makes this a public subnet
    availability_zone = "us-east-1a"

    tags = {
        Name = "subnet-demo"
    }
}

#subnet-private
resource "aws_subnet" "subnet_b" {                                  #creation of private subnet
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = "false" 		#it makes this a private subnet
    availability_zone = "us-east-1b"

    tags = {
        Name = "subnet-demo1"
    }
}

#internet gateway
resource "aws_internet_gateway" "igw" {                             #creation of internet gateway
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "prod-igw"
    }
}

#routetable-public                                               		 #creation of routetable public
resource "aws_route_table" "route_a" {
    vpc_id = aws_vpc.vpc.id
    
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id                  #internet gateway association to public route
  }

    tags = {
        Name = "route-demo"
    }
}
  #association of public subnet to the route
resource "aws_route_table_association" "association"{
    subnet_id = aws_subnet.subnet_a.id
    route_table_id = aws_route_table.route_a.id
}

#nat-gatway
resource "aws_eip" "nat_gateway1" {                           	  #creation of elastic ip
  vpc = "true"
  
  tags = {
    name = "elastic"
  }
}
  
 #creation of NAT gateway

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway1.id
  subnet_id = aws_subnet.subnet_a.id
  tags = {
    name = "NAT"
  }
}

#routetable-private
resource "aws_route_table" "route_b" {                          		#creation of private route
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat_gateway.id            		 #updating of NAT gateway to private route
    }
     tags = {
        Name = "route-demo1"
    }
}

resource "aws_route_table_association" "association1"{ 
    subnet_id = aws_subnet.subnet_b.id
    route_table_id = aws_route_table.route_b.id
}


#security group                                                    				 #security group instance
resource "aws_security_group" "security" {
    vpc_id = aws_vpc.vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "sg"
    }
}

#public instance                                               			 #creating the public instance
resource "aws_instance" "ec1" {
  ami = "ami-09538990a0c4fe9be"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet_a.id
  associate_public_ip_address = "true"
  key_name = "lin-key-sp"
  vpc_security_group_ids = [aws_security_group.security.id]
  
  tags = {
        Name = "public"
    }
}  

#private instance					#creating the private instance
resource "aws_instance" "ec2" {
  ami = "ami-09538990a0c4fe9be"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet_b.id
  associate_public_ip_address = "false"
  key_name = "lin-key-sp"
  vpc_security_group_ids = [aws_security_group.security.id]
  
  tags = {
        Name = "private"
    }
}

