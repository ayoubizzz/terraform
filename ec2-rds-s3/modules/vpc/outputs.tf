output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = values(aws_subnet.public).*.id
}

output "private_subnet_ids" {
  value = values(aws_subnet.private).*.id
}

output "db_subnet_ids" {
  value = values(aws_subnet.db).*.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.nat.*.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}