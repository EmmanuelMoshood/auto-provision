
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "terraform_profile"
}

# Create a VPC
resource "aws_vpc" "bramton_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "bramton_vpc"
  }
}

# # data source to get the list of all az in our region
# data "aws_availability_zones" "my_region_available_zones" {}

# create 2 private subnet and 2 public subnets in 2 different AZs
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.bramton_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.bramton_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.bramton_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id            = aws_vpc.bramton_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public-subnet-2"
  }
}

#create internet gateway
resource "aws_internet_gateway" "bramton-igw" {
  vpc_id = aws_vpc.bramton_vpc.id
  tags = {
    Name = "bramton-vpc-IGW"
  }
}

#route table to associate with public subnet
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.bramton_vpc.id
  tags = {
    Name = "public-route-table"
  }
}
resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bramton-igw.id
}

resource "aws_route_table_association" "public-subnet-1-association" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet-2-association" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-route-table.id
}


#NAT gateway to enable connectivity to the private subnet
resource "aws_eip" "nat-eip" {
  vpc = true
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "nat-gateway"
  }
}




#security groups
resource "aws_security_group" "web-sg" {
  vpc_id = aws_vpc.bramton_vpc.id
  name   = "web-sg"

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "web-sg"
  }
}

resource "aws_security_group" "db-sg" {
  vpc_id = aws_vpc.bramton_vpc.id
  name   = "db-sg"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
    # Allow traffic from private subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}


# provision the rds instance
# create the subnet group for the rds instance
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "database-subnets"
  subnet_ids   = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
  description = "subnets for database instance"

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_instance" "db_instance" {
  engine                 = "mysql"
  engine_version         = "8.0.31"
  multi_az               = false
  identifier             = "dev-rds-instance"
  username               = "admin"
  password               = "Admin123"
  instance_class         = "db.t3.micro"
  allocated_storage      = 200
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  availability_zone      = "us-east-1a"
  db_name                = "my_db"
  skip_final_snapshot    = true
}


# provision ec2 instances
resource "aws_instance" "private-instance" {
  ami           = "ami-080e1f13689e07408"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private-subnet-1.id
  tags = {
    Name = "private-instance"
  }
}

resource "aws_instance" "public-instance" {
  ami           = "ami-080e1f13689e07408"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public-subnet-1.id
  tags = {
    Name = "public-instance"
  }
}
