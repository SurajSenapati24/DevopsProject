variable "aws_region" {
  description = "AWS region"
  default     = "ap-southeast-2"
}

variable "ami_id" {
  description = "Ubuntu AMI for your region"
  default     = "ami-010876b9ddd38475e" 
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  default     = "two-tier" # update as needed
}

variable "dockerhub_username" {
  description = "Your DockerHub username"
  default     = "surajsenapati"
}
