resource "aws_security_group" "nomad-edge-sg" {
  name = "nomad-edge-sg"
  vpc_id = aws_vpc.nomad-vpc.id
}

resource "aws_security_group_rule" "nomad-edge-icmp" {
  type = "ingress"
  protocol = "icmp"
  from_port = -1
  to_port = -1
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-ssh" {
  type = "ingress"
  protocol = "TCP"
  from_port = 22
  to_port = 22
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-http-api" {
  type = "ingress"
  protocol = "TCP"
  from_port = 4646
  to_port = 4646
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-rpc" {
  type = "ingress"
  protocol = "TCP"
  from_port = 4647
  to_port = 4647
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-consul-lan-serf-tcp" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8301
  to_port = 8301
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-consul-lan-serf-udp" {
  type = "ingress"
  protocol = "UDP"
  from_port = 8301
  to_port = 8301
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-consul-ports" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8500
  to_port = 8503
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-node-exporter" {
  type = "ingress"
  protocol = "TCP"
  from_port = 9100
  to_port = 9100
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-tasks-dynamic-ports" {
  type = "ingress"
  protocol = "TCP"
  from_port = 20000
  to_port = 32000
  cidr_blocks = ["172.16.0.0/24", "0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_security_group_rule" "nomad-edge-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.nomad-edge-sg.id
}

resource "aws_iam_policy" "nomad-edge-policy" {
  name        = "nomad-edge-policy"
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

resource "aws_iam_role" "nomad-edge-role" {
  name = "nomad-edge-role"

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

resource "aws_iam_policy_attachment" "nomad-edge-policy-attachemnt" {
  name       = "nomad-edge-policy-attachment"
  roles      = [aws_iam_role.nomad-edge-role.name]
  policy_arn = aws_iam_policy.nomad-edge-policy.arn
}

resource "aws_iam_instance_profile" "nomad-edge-iam-profile" {
  name = "nomad-edge-iam-profile"
  role = aws_iam_role.nomad-edge-role.name
}

data "aws_ami" "nomad-edge-ami" {
  name_regex = "${lookup(var.nomad-edge, "ami_name")}"
  owners = ["self"]
}

data "cloudinit_config" "nomad-edge-cloud-init" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/nomad-base-cloud-init.yaml.tpl",{})
  }
}

resource "aws_launch_template" "nomad-edge-tmpl" {
  name_prefix = "${lookup(var.nomad-edge, "prefix")}"
  
  image_id = data.aws_ami.nomad-edge-ami.id
  instance_type = "${lookup(var.nomad-edge, "instance_type")}"
 
  iam_instance_profile {
    name = "nomad-edge-iam-profile"
  } 

  user_data = data.cloudinit_config.nomad-edge-cloud-init.rendered

  vpc_security_group_ids = [aws_security_group.nomad-edge-sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${lookup(var.nomad-edge, "prefix")}"
      Role = "nomad-edge"
    }
  }

  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "nomad-edge-asg" {
  name_prefix = "${lookup(var.nomad-edge, "prefix")}"

  max_size = "${lookup(var.nomad-edge, "pool_size")}"
  min_size = "${lookup(var.nomad-edge, "pool_size")}"

  vpc_zone_identifier = [for subnet in aws_subnet.nomad-subnet : subnet.id]

  launch_template {
    id = aws_launch_template.nomad-edge-tmpl.id
    version = "$Latest"
  }
}
