resource "aws_security_group" "nomad-server-sg" {
  name = "nomad-server-sg"
  vpc_id = aws_vpc.nomad-vpc.id
}

resource "aws_security_group_rule" "nomad-server-icmp" {
  type = "ingress"
  protocol = "icmp"
  from_port = -1
  to_port = -1
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-server-sg.id
}

resource "aws_security_group_rule" "nomad-server-ssh" {
  type = "ingress"
  protocol = "TCP"
  from_port = 22
  to_port = 22
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-server-sg.id
}

resource "aws_security_group_rule" "nomad-server-http-api" {
  type = "ingress"
  protocol = "TCP"
  from_port = 4646
  to_port = 4646
  cidr_blocks = ["172.16.0.0/24", "0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-server-sg.id
}

resource "aws_security_group_rule" "nomad-server-rpc" {
  type = "ingress"
  protocol = "TCP"
  from_port = 4647
  to_port = 4647
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.nomad-server-sg.id
}

resource "aws_security_group_rule" "nomad-server-serf-tcp" {
  type = "ingress"
  protocol = "TCP"
  from_port = 4648
  to_port = 4648
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.nomad-server-sg.id
}

resource "aws_security_group_rule" "nomad-server-serf-udp" {
  type = "ingress"
  protocol = "UDP"
  from_port = 4648
  to_port = 4648
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.nomad-server-sg.id
}

resource "aws_security_group_rule" "nomad-server-consul-lan-serf-tcp" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8301
  to_port = 8301
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-server-sg.id
}

resource "aws_security_group_rule" "nomad-server-consul-lan-serf-udp" {
  type = "ingress"
  protocol = "UDP"
  from_port = 8301
  to_port = 8301
  cidr_blocks = ["172.16.0.0/24"]
  security_group_id = aws_security_group.nomad-server-sg.id
}

resource "aws_security_group_rule" "nomad-server-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.nomad-server-sg.id
}

data "aws_ami" "nomad-server-ami" {
  name_regex = "${lookup(var.nomad-server, "ami_name")}"
  owners = ["self"]
}

data "cloudinit_config" "nomad-server-cloud-init" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/nomad-base-cloud-init.yaml.tpl",{})
  }
}

resource "aws_launch_template" "nomad-server-tmpl" {
  name_prefix = "${lookup(var.nomad-server, "prefix")}"
  
  image_id = data.aws_ami.nomad-server-ami.id
  instance_type = "${lookup(var.nomad-server, "instance_type")}"
  
  user_data = data.cloudinit_config.nomad-server-cloud-init.rendered

  vpc_security_group_ids = [aws_security_group.nomad-server-sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${lookup(var.nomad-server, "prefix")}"
      Role = "nomad-server"
    }
  }

  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "nomad-server-asg" {
  name_prefix = "${lookup(var.nomad-server, "prefix")}"

  target_group_arns = [aws_lb_target_group.nomad-server-http-api-tg.arn, aws_lb_target_group.nomad-server-http-api-tg-int.arn]

  max_size = "${lookup(var.nomad-server, "max_size")}"
  min_size = "${lookup(var.nomad-server, "min_size")}"

  vpc_zone_identifier = [for subnet in aws_subnet.nomad-subnet : subnet.id]

  launch_template {
    id = aws_launch_template.nomad-server-tmpl.id
    version = "$Latest"
  }
}
