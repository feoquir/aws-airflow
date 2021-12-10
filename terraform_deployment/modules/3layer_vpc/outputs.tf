output "vpc" {
  value = aws_vpc.main
}

output "public_sn" {
  value = aws_subnet.public_sn
}

output "private_sn" {
  value = aws_subnet.private_sn
}

output "data_sn" {
  value = aws_subnet.data_sn
}