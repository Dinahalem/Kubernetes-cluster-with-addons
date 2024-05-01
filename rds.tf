#Create RDS database

# configured aws provider with proper credentials
provider "aws" {
  region  = "us-east-1"
}


# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {

  tags = {
    Name = "default vpc"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}


# create a default subnet in the first az if one does not exit
resource "aws_default_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]
}

# create a default subnet in the second az if one does not exit
resource "aws_default_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.available_zones.names[1]
}
}

# create security group for the web
resource "aws_security_group" "web_security_group" {
  name        = "web security group"
  description = "enable http access on port 80"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [0.0.0.0/0]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [0.0.0.0/0]
  }

  tags   = {
    Name = "web-security-group"
  }
}

# create security group for the database
resource "aws_security_group" "database_security_group" {
  name        = "database security group"
  description = "enable database access on port 3306"
  vpc_id      = 

  ingress {
    description      = "database access"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.web_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = [0.0.0.0/0]
  }

  tags   = {
    Name = "database security group"
  }
}


# create the subnet group for the rds instance
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "database-subnets"
  subnet_ids   = [aws_default_subnet.subnet_az1.id, aws_default_subnet.subnet_az2.id]
  description  = "subnets for database"

  tags   = {
    Name = "database-subnets"
  }
}


# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                  = "mysql"
  engine_version          = "8.0.31"
  multi_az                = false
  identifier              = "dev-rds-instance"
  username                = "webapp"
  password                = "webapp12345"
  instance_class          = "db.t2.micro"
  allocated_storage       = 200
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.database_security_group.id]
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  db_name                 = "applicationdb"
  skip_final_snapshot     = true

  tags   = {
    Name = "rdsdb"
  }
}

#retrieve hostname
output "rds_hostname" {
  value = aws_db_instance.db_instance.endpoint
}
