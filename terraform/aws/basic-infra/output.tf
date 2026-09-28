output "VPC_Id" {
  value = aws_vpc.devops-lab-vpc.id
}

output "Subnet_Id" {
  value = aws_subnet.devops-lab-subnet-public.id
}

output "Security_Group_Id" {
  value = aws_security_group.devops-lab-sg.id
}

output "EC2_Instance_Id" {
  value = aws_instance.devops-lab-web-server.id
}

output "EC2_Instance_Public_IP" {
  value = aws_instance.devops-lab-web-server.public_ip
}