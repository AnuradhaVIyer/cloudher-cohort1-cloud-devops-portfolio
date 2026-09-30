variable "aws_region" {
    description = "The AWS region to deploy resources in."
    type = string
    default = "us-east-1" 
}

variable "bucket_prefix" {
    description = "Prefix for the state bucket name."
    type = string
    default = "devops-lab-tfstate"
}