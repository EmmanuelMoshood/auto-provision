
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
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "bramton_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "bramton_vpc"
  }
}

# data source to get the list of all az in our region
data "aws_availability_zones" "all_available_zones" {}

# create a subnet in the first az
resource "aws_default_subnet" "private_subnet1" {
  availability_zone = data.aws_availability_zones.all_available_zones.names[0]
}

# create a subnet in the second az
resource "aws_default_subnet" "private_subnet2" {
  availability_zone = data.aws_availability_zones.all_available_zones.names[1]
}




# sg for the webserver
resource "aws_security_group" "webserver_sg" {
   name        = "webserver_sg"
  description = "Allow http traffic on port 80"
  vpc_id      = aws_vpc.bramton_vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver_sg"
  }
}

# sg for the db
resource "aws_security_group" "rds_db_sg" {
   name        = "rds_db_sg"
  description = "Allow mysql on port 3306"
  vpc_id      = aws_vpc.bramton_vpc.id

  ingress {
    description = "mysql_access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups = [aws_security_group.webserver_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_db_sg"
  }
}

resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "database-subnets"
  subnet_ids = [aws_default_subnet.private_subnet1.id, aws_default_subnet.private_subnet2.id]
  description = "subnets for database instance"

  tags = {
    Name = "My DB subnet group"
  }
}



# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                  = "mysql"
  engine_version          = "8.0.31"
  multi_az                = false
  identifier              = "dev-rds-instance"
  username                = "admin"
  password                = "Admin123"
  instance_class          = "db.t2.micro"
  allocated_storage       = 200
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_db_sg.id]
  availability_zone       = data.aws_availability_zones.all_available_zones.names[0]
  db_name                 = "my_db"
  skip_final_snapshot     = true
}