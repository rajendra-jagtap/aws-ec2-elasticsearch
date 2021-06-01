#############################################################
# data sources to get vpc, subnet, ami...
#############################################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name      = "name"
    values    = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name      = "owner-alias"
    values    = ["amazon"]
  }
}

#############################################################
# Create Security Group For EC2 Cluster
#############################################################

resource "aws_security_group" "ec2-sg" {
  name              = "${var.environment}-elasticsearch-sg"
  description       = "Security group for ElasticSearch Cluster"
  vpc_id            = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port       = 8
    to_port         = 0
    protocol        = "icmp"
    description     = "ping"
    cidr_blocks     = [var.vpc_cidr]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    description     = "ssh"
    cidr_blocks     = [var.vpc_cidr]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    description     = "ssh"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}


#############################################################
# Setup EC2 Cluster
#############################################################

resource "aws_instance" "ec2" {
  ami                      = data.aws_ami.amazon_linux.id
  count                    = length(var.private_ips)
  instance_type            = var.instance_type
  key_name                 = var.key_name
  ebs_optimized            = var.ebs_optimized
  vpc_security_group_ids   = [aws_security_group.ec2-sg.id]
  subnet_id                = element(var.public_subnet_id, count.index)
# iam_instance_profile     = aws_iam_instance_profile.instance-profile.name
  private_ip               = var.private_ips[count.index]
  disable_api_termination  = var.disable_api_termination
  monitoring               = var.monitoring
  lifecycle {
    ignore_changes         = [ami]
  }
  tags =  {
    Name                   = "${var.environment}-elasticsearch${count.index + 1}"
    Environment            = var.environment
  }
  root_block_device {
    volume_type            = var.root_volume_type
    volume_size            = var.root_volume_size
    delete_on_termination  = var.delete_on_termination
  }
}

