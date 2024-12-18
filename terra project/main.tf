# AWS provider configuration
provider "aws" {
  region = "us-east-1"  # Adjust the region as needed
}

# AWS VPC resource using the vpc_cidr variable
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# AWS Subnet resources using availability_zone_1 and availability_zone_2 variables
resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true
}
