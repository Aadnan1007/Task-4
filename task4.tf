provider "aws" {
   region ="ap-south-1"
    profile = "adnanshk"
    access_key = "$your_access_key"
    secret_key = "$Your_Security_Key"  
}

#Create VPC
resource "aws_vpc" "adnanskvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames  = true

  tags = {
    Name = "adnanvpc"
  }
}
#Creating Public Subnet
resource "aws_subnet" "public" {
  vpc_id     = "vpc-00853717f8c157e42"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "adnanpublicsubnet"
  }
}
#Creating Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = "vpc-00853717f8c157e42"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "adnanprivatesubnet"
  }
}
#Security Group for WordPress Webserver
resource "aws_security_group" "webserver" {
  name        = "for_wordpress"
  description = "Allow hhtp,ssh"
  vpc_id      = "vpc-00853717f8c157e42"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver_sg"
  }
}
#Instance for Wordpress
resource "aws_instance" "wordpress_inst" {
    ami = "ami-052c08d70def0ac62"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    subnet_id = "subnet-0a031cdad762e39d2"
    key_name = "adnan1818"
    vpc_security_group_ids = [ "sg-047f65e96e242ae70" ]
    tags = {
        Name = "Wordpress_Server"
    }
}
#Creating Internet Gateway
resource "aws_internet_gateway" "adnangw" {
  vpc_id = "vpc-00853717f8c157e42"

  tags = {
    Name = "adnanig"
  }
}
#Creating Routing table for Internet Gateway
resource "aws_route_table" "forig" {
  vpc_id = "vpc-00853717f8c157e42"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "igw-0a6ca5d3d852e4401"
  }

  tags = {
    Name = "adnanigroutetable"
  }
}
#Associating the reouting table
resource "aws_route_table_association" "associatetopublic" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.forig.id
}
#Security Group for Database
resource "aws_security_group" "database" {
  name        = "for_MYSQL"
  description = "Allow ssh and MYSQL"
  vpc_id      = "vpc-00853717f8c157e42"

  ingress {
    description = "MYSQL"
    security_groups = [aws_security_group.webserver.id]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wpdatabase_sg"
  }
}
# Security group created for Batson :
resource "aws_security_group" "batsonsg" {
  name        = "batson"
  description = "Security group for VPC"
  vpc_id      = "vpc-00853717f8c157e42"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "batsonmysg"
  }
}
#Instance for batson on public subnet
resource "aws_instance" "batson_inst" {
    ami = "ami-07a8c73a650069cf3"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    subnet_id = "subnet-0a031cdad762e39d2"
    key_name = "adnan1818"
    vpc_security_group_ids = [ "sg-0e8b5465741b1c464" ]
    tags = {
        Name = "Batson_Instance"
    }
}
#Create Mysql instance and attach 2 security groups to it
resource "aws_instance" "mysql_inst" {
    ami = "ami-07a8c73a650069cf3"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    subnet_id = "subnet-0b971bd1891fab3e5"
    key_name = "adnan1818"
    vpc_security_group_ids = [ "sg-00554b09eaff6b6de" , "sg-0e8b5465741b1c464" ]
    depends_on = [
        aws_security_group.batsonsg
    ]
    tags = {
        Name = "WordPressDB"
    }
}
resource "null_resource" "cluster" {
  depends_on = [
      aws_instance.wordpress_inst,
      aws_instance.mysql_inst
  ]
}
#Security group that make batson to allow in mysql:
resource "aws_security_group" "mysqlbatsonsg" {
  name        = "mysqlbatson"
  description = "Security group for VPC"
  vpc_id      = "vpc-00853717f8c157e42"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysqlbatson"
  }
}
#Allocate EIP
resource "aws_eip" "nat" {
  vpc=true
  
}
#Create NAT Gateway
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "eipalloc-005eb80283316b34e"
  subnet_id     = "subnet-0a031cdad762e39d2"
  depends_on = [aws_internet_gateway.adnangw]

  tags = {
    Name = "gw NAT"
  }
}
#Create route table for making path to NAT
resource "aws_route_table" "forprivate" {
  vpc_id = "vpc-00853717f8c157e42"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "nat-07f8c901b30c5c6fc"
  }
  tags = {
    Name = "fordatabase"
  }
}
#Associate this Routing table to the private subnet.
resource "aws_route_table_association" "nat" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.forprivate.id
}






