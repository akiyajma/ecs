locals {
  prefix-name = "main"
  region      = "ap-northeast-1"
  vpc = {
    name = "main"
    cidr = "172.10.0.0/16"
  }
  public-subnet = {
    public-az-1a = {
      az   = "ap-northeast-1a",
      cird = "172.10.10.0/24",
    },
    public-az-1c = {
      az   = "ap-northeast-1c",
      cird = "172.10.11.0/24",
    },
    public-az-1d = {
      az   = "ap-northeast-1d",
      cird = "172.10.12.0/24",
    },
  }
  private-subnet = {
    private-az-1a = {
      az   = "ap-northeast-1a",
      cird = "172.10.20.0/24",
    },
    private-az-1c = {
      az   = "ap-northeast-1c",
      cird = "172.10.21.0/24",
    },
    private-az-1d = {
      az   = "ap-northeast-1d",
      cird = "172.10.22.0/24",
    },
  }
  private-nat-subnet = {
    private-nat-az-1a = {
      az   = "ap-northeast-1a",
      cird = "172.10.30.0/24",
    },
    private-nat-az-1c = {
      az   = "ap-northeast-1c",
      cird = "172.10.31.0/24",
    },
    private-nat-az-1d = {
      az   = "ap-northeast-1d",
      cird = "172.10.32.0/24",
    },
  }
}

###
# VPC
###
resource "aws_vpc" "main" {
  cidr_block           = local.vpc.cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = local.vpc.name
  }
}

###
# Subnet
###
# public
resource "aws_subnet" "public" {
  for_each          = local.public-subnet
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cird
  availability_zone = each.value.az

  tags = {
    Name = "${local.prefix-name}-${each.key}"
  }
}

# private
resource "aws_subnet" "private" {
  for_each          = local.private-subnet
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cird
  availability_zone = each.value.az

  tags = {
    Name = "${local.prefix-name}-${each.key}"
  }
}

###
## Internet Gateway
###
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.prefix-name}"
  }
}

###
# Nat Gateway
###
resource "aws_eip" "main" {
  for_each = local.public-subnet
  vpc      = true
  tags = {
    Name = "${local.prefix-name}-${each.key}"
  }
}

resource "aws_nat_gateway" "main" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.main[each.key].id
  subnet_id     = each.value.id
  tags = {
    Name = "${local.prefix-name}-${each.key}"
  }
  depends_on = [aws_internet_gateway.main]
}

###
# Route table
###
# public
resource "aws_route_table" "public" {
  for_each = local.public-subnet
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${local.prefix-name}-${each.key}"
  }
}

resource "aws_route" "public" {
  for_each               = aws_route_table.public
  route_table_id         = each.value.id
  gateway_id             = aws_internet_gateway.main.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.key].id
}

# private
resource "aws_route_table" "private" {
  for_each = local.private-subnet
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${local.prefix-name}-${each.key}"
  }
}

resource "aws_route" "private" {
  for_each               = zipmap(keys(local.public-subnet), keys(local.private-subnet))
  route_table_id         = aws_route_table.private[each.value].id
  nat_gateway_id         = aws_nat_gateway.main[each.key].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

###
# VPC Endopoint for Gateway
###
#resource "aws_vpc_endpoint" "s3" {
#  vpc_id            = aws_vpc.main.id
#  vpc_endpoint_type = "Gateway"
#  service_name      = "com.amazonaws.${local.region}.s3"
#  tags = {
#    Name = "${local.prefix-name}"
#  }
#}

#resource "aws_vpc_endpoint" "ecr-dkr" {
#  vpc_id              = aws_vpc.main.id
#  vpc_endpoint_type   = "Interface"
#  service_name        = "com.amazonaws.${local.region}.ecr.dkr"
#  private_dns_enabled = true
#  security_group_ids  = [aws_security_group.vpc_endpoint.id]
#  subnet_ids = [
#    for subnet in aws_subnet.private :
#    subnet.id
#  ]
#  tags = {
#    Name = "${local.prefix-name}"
#  }
#}
#
#resource "aws_vpc_endpoint" "ecr-api" {
#  vpc_id              = aws_vpc.main.id
#  vpc_endpoint_type   = "Interface"
#  service_name        = "com.amazonaws.${local.region}.ecr.api"
#  private_dns_enabled = true
#  security_group_ids  = [aws_security_group.vpc_endpoint.id]
#  subnet_ids = [
#    for subnet in aws_subnet.private :
#    subnet.id
#  ]
#  tags = {
#    Name = "${local.prefix-name}"
#  }
#}
#
#resource "aws_vpc_endpoint" "logs" {
#  vpc_id              = aws_vpc.main.id
#  vpc_endpoint_type   = "Interface"
#  service_name        = "com.amazonaws.${local.region}.logs"
#  private_dns_enabled = true
#  security_group_ids  = [aws_security_group.vpc_endpoint.id]
#  subnet_ids = [
#    for subnet in aws_subnet.private :
#    subnet.id
#  ]
#  tags = {
#    Name = "${local.prefix-name}"
#  }
#}

#resource "aws_vpc_endpoint" "ssm" {
#  vpc_id              = aws_vpc.main.id
#  vpc_endpoint_type   = "Interface"
#  service_name        = "com.amazonaws.${local.region}.ssm"
#  private_dns_enabled = true
#  security_group_ids  = [aws_security_group.vpc_endpoint.id]
#  subnet_ids = [
#    for subnet in aws_subnet.public :
#    subnet.id
#  ]
#  tags = {
#    Name = "${local.prefix-name}"
#  }
#}
#
#resource "aws_vpc_endpoint" "ssmmessages" {
#  vpc_id              = aws_vpc.main.id
#  vpc_endpoint_type   = "Interface"
#  service_name        = "com.amazonaws.${local.region}.ssmmessages"
#  private_dns_enabled = true
#  security_group_ids  = [aws_security_group.vpc_endpoint.id]
#  subnet_ids = [
#    for subnet in aws_subnet.public :
#    subnet.id
#  ]
#  tags = {
#    Name = "${local.prefix-name}"
#  }
#}
#
#resource "aws_vpc_endpoint" "ec2messages" {
#  vpc_id              = aws_vpc.main.id
#  vpc_endpoint_type   = "Interface"
#  service_name        = "com.amazonaws.${local.region}.ec2messages"
#  private_dns_enabled = true
#  security_group_ids  = [aws_security_group.vpc_endpoint.id]
#  subnet_ids = [
#    for subnet in aws_subnet.public :
#    subnet.id
#  ]
#  tags = {
#    Name = "${local.prefix-name}"
#  }
#}

# public
#resource "aws_vpc_endpoint_route_table_association" "public-s3" {
#  for_each        = aws_route_table.public
#  vpc_endpoint_id = aws_vpc_endpoint.s3.id
#  route_table_id  = each.value.id
#}

# private
#resource "aws_vpc_endpoint_route_table_association" "private-s3" {
#  for_each        = aws_route_table.private
#  vpc_endpoint_id = aws_vpc_endpoint.s3.id
#  route_table_id  = each.value.id
#}

###
# Security group
###
resource "aws_security_group" "vpc_endpoint" {
  name   = "vpc_endpoint_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs-puppet" {
  name   = "ecs_puppet"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8140
    to_port     = 8140
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name   = "alb"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "postgres" {
  name   = "ecs_postgres"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "puppetdb" {
  name   = "ecs_puppetdb"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "puppetserver" {
  name   = "ecs_puppeserver"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 8140
    to_port     = 8140
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "puppetboard" {
  name   = "ecs_puppetboard"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 9090
    to_port   = 9090
    protocol  = "tcp"
    #cidr_blocks = [aws_vpc.main.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
