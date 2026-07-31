resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name      = "${var.vpc_name}-public-rt"
    Tier      = "public"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# No default route: a database in these subnets needs no outbound internet, and
# a NAT Gateway would cost more than everything else in this stack combined.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name      = "${var.vpc_name}-private-rt"
    Tier      = "private"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
