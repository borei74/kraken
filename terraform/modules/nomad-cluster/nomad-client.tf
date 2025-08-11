resource "aws_security_group" "nomad-client-sg" {
  name = "nomad-client-sg"
  vpc_id = aws_vpc.nomad-vpc.id
}

resource "aws_security_group_rule" "nomad-client-icmp" {
  type = "ingress"
  protocol = "icmp"
  from_port = -1
  to_port = -1
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-client-ssh" {
  type = "ingress"
  protocol = "TCP"
  from_port = 22
  to_port = 22
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-client-http-api" {
  type = "ingress"
  protocol = "TCP"
  from_port = 4646
  to_port = 4646
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-client-rpc" {
  type = "ingress"
  protocol = "TCP"
  from_port = 4647
  to_port = 4647
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-client-consul-lan-serf-tcp" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8301
  to_port = 8301
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-client-consul-lan-serf-udp" {
  type = "ingress"
  protocol = "UDP"
  from_port = 8301
  to_port = 8301
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-client-consul-ports" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8500
  to_port = 8503
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-node-exporter" {
  type = "ingress"
  protocol = "TCP"
  from_port = 9100
  to_port = 9100
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-tasks-dynamic-ports" {
  type = "ingress"
  protocol = "TCP"
  from_port = 20000
  to_port = 32000
  cidr_blocks = ["172.16.0.0/24", "0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_security_group_rule" "nomad-client-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.nomad-client-sg.id
}

resource "aws_iam_policy" "nomad-kraken-client-policy" {
  name        = "nomad-kraken-client-policy"
  description = "Provides permissions to get an access to AWS EBS volumes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:AttachVolume",
          "ec2:DetachVolume"
        ]
        Effect   = "Allow"
        Resource = [
          "*" ]
      },
    ]
  })
}

resource "aws_iam_role" "nomad-kraken-client-role" {
  name = "nomad-kraken-client-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "nomad-client-policy-attachemnt" {
  name       = "nomad-client-policy-attachment"
  roles      = [aws_iam_role.nomad-kraken-client-role.name]
  policy_arn = aws_iam_policy.nomad-kraken-client-policy.arn
}

resource "aws_iam_instance_profile" "nomad-kraken-client-iam-profile" {
  name = "nomad-kraken-client-iam-profile"
  role = aws_iam_role.nomad-kraken-client-role.name
}

data "aws_ami" "nomad-client-ami" {
  name_regex = "${lookup(var.nomad-client, "ami_name")}"
  owners = ["self"]
}

data "cloudinit_config" "nomad-client-cloud-init" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/nomad-base-cloud-init.yaml.tpl",{})
  }
}

resource "aws_launch_template" "nomad-client-tmpl" {
  name_prefix = "${lookup(var.nomad-client, "prefix")}"
  
  image_id = data.aws_ami.nomad-client-ami.id
  instance_type = "${lookup(var.nomad-client, "instance_type")}"
 
  iam_instance_profile {
    name = "nomad-client-iam-profile"
  } 

  user_data = data.cloudinit_config.nomad-client-cloud-init.rendered

  vpc_security_group_ids = [aws_security_group.nomad-client-sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${lookup(var.nomad-client, "prefix")}"
      Role = "nomad-client"
    }
  }

  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "nomad-client-asg" {
  name_prefix = "${lookup(var.nomad-client, "prefix")}"

  max_size = "${lookup(var.nomad-client, "max_size")}"
  min_size = "${lookup(var.nomad-client, "min_size")}"

  vpc_zone_identifier = [for subnet in aws_subnet.nomad-subnet : subnet.id]

  launch_template {
    id = aws_launch_template.nomad-client-tmpl.id
    version = "$Latest"
  }
}
