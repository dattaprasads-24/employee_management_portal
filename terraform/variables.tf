variable "aws_region" {
  default = "ap-south-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_backend_cidr" {
  default = "10.0.2.0/24"
}

variable "private_db_cidr" {
  default = "10.0.3.0/24"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "jenkins_instance_type" {
  default = "c7i-flex.large"
}
