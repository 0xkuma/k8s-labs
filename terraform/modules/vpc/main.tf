resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-vpc"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each       = toset(var.subnets.public)
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[each.key].id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-private-rt"
    }
  )
}

resource "aws_route_table_association" "private" {
  for_each       = toset(var.subnets.private)
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[each.key].id
}

resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-default-sg"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-igw"
    }
  )
}

resource "aws_eip" "main" {
  domain = "vpc"

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = aws_subnet.public[var.subnets.public[0]].id

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-nat"
    }
  )
}

resource "aws_subnet" "public" {
  for_each   = toset(var.subnets.public)
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-public-${index(var.subnets.public, each.key)}"
    }
  )
}

resource "aws_subnet" "private" {
  for_each   = toset(var.subnets.private)
  vpc_id     = aws_vpc.main.id
  cidr_block = each.value

  tags = merge(
    local.bTags,
    {
      Name = "${local.pTags}-private-${index(var.subnets.private, each.key)}"
    }
  )
}

resource "aws_security_group" "bastion" {
  name        = "${local.pTags}-bastion-sg"
  description = "Bastion security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "master" {
  name        = "${local.pTags}-master-sg"
  description = "Master security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "worker" {
  name        = "${local.pTags}-worker-sg"
  description = "Worker security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
