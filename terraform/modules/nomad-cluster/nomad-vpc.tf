resource "aws_vpc" "nomad-vpc" {
  cidr_block = "${lookup(var.nomad-vpc, "cidr_block")}"

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${lookup(var.nomad-vpc, "name")}"  
  }
}

data "aws_route53_zone" "nomad-dns-zone" {
  name         = var.nomad-dns-zone
  private_zone = true
}

resource "aws_route53_zone_association" "nomad-vpc-soleks-net-assoc" {
  zone_id = data.aws_route53_zone.nomad-dns-zone.zone_id
  vpc_id  = aws_vpc.nomad-vpc.id
}

resource "aws_internet_gateway" "nomad-vpc-igw" {
  vpc_id = aws_vpc.nomad-vpc.id

  tags = {
    Name = "${lookup(var.nomad-vpc, "name")}-igw"  
  }
}

resource "aws_subnet" "nomad-subnet" {
  vpc_id = aws_vpc.nomad-vpc.id
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"

  cidr_block = "${cidrsubnet(lookup(var.nomad-vpc, "cidr_block"), 4, count.index)}"
  availability_zone = "${lookup(var.nomad-vpc, "region")}${element(lookup(var.nomad-vpc,"availability_zones"),count.index)}"

  tags = {
    Name = "${lookup(var.nomad-vpc, "name")}-subnet-${element(lookup(var.nomad-vpc,"availability_zones"),count.index)}"
  }
}

resource "aws_subnet" "nomad-subnet-pub" {
  vpc_id = aws_vpc.nomad-vpc.id
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"

  cidr_block = "${cidrsubnet(lookup(var.nomad-vpc, "cidr_block"), 4, count.index+length(lookup(var.nomad-vpc,"availability_zones")))}"
  availability_zone = "${lookup(var.nomad-vpc, "region")}${element(lookup(var.nomad-vpc,"availability_zones"),count.index)}"

  tags = {
    Name = "${lookup(var.nomad-vpc, "name")}-subnet-${element(lookup(var.nomad-vpc,"availability_zones"),count.index)}"
  }
}

resource "aws_eip" "nomad-natgw-eip" {
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"
  vpc = true
}

resource "aws_nat_gateway" "nomad-vpc-natgw" {
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"
  
  allocation_id = aws_eip.nomad-natgw-eip[count.index].id
  subnet_id = aws_subnet.nomad-subnet-pub[count.index].id

  depends_on = [aws_internet_gateway.nomad-vpc-igw]
}

resource "aws_route_table" "nomad-vpc-rt" {
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"

  vpc_id = aws_vpc.nomad-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nomad-vpc-natgw[count.index].id
  }
}

resource "aws_route_table_association" "nomad-vpc-rt-assoc" {
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"
  
  subnet_id = aws_subnet.nomad-subnet[count.index].id
  route_table_id = aws_route_table.nomad-vpc-rt[count.index].id
}

resource "aws_default_route_table" "nomad-defaul-route-table" {
  default_route_table_id = aws_vpc.nomad-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nomad-vpc-igw.id
  }

  tags = {
    Name = "${lookup(var.nomad-vpc, "name")}-default-route-table"
  }
}
