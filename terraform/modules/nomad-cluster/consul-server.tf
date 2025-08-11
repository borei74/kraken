resource "aws_security_group" "consul-server-sg" {
  name = "consul-server-sg"
  vpc_id = aws_vpc.nomad-vpc.id
}

resource "aws_security_group_rule" "consul-server-icmp" {
  type = "ingress"
  protocol = "icmp"
  from_port = -1
  to_port = -1
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-ssh" {
  type = "ingress"
  protocol = "TCP"
  from_port = 22
  to_port = 22
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-http-api" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8500
  to_port = 8500
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-https-api" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8501
  to_port = 8501
  cidr_blocks = ["172.16.0.0/24", "0.0.0.0/0"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-grpc" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8502
  to_port = 8503
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-rpc" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8300
  to_port = 8300
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-lan-serf-tcp" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8301
  to_port = 8301
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-lan-serf-udp" {
  type = "ingress"
  protocol = "UDP"
  from_port = 8301
  to_port = 8301
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-wan-serf-tcp" {
  type = "ingress"
  protocol = "TCP"
  from_port = 8302
  to_port = 8302
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-wan-serf-udp" {
  type = "ingress"
  protocol = "UDP"
  from_port = 8302
  to_port = 8302
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-sidecar-proxy" {
  type = "ingress"
  protocol = "TCP"
  from_port = 21000
  to_port = 21255
  cidr_blocks = ["172.16.0.0/24", "75.157.3.0/24"]
  security_group_id = aws_security_group.consul-server-sg.id
}

resource "aws_security_group_rule" "consul-server-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.consul-server-sg.id
}

data "aws_ami" "consul-server-ami" {
  name_regex = "${lookup(var.consul-server, "ami_name")}"
  owners = ["self"]
}

data "cloudinit_config" "consul-server-cloud-init" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/consul-base-cloud-init.yaml.tpl",{})
  }
}

resource "aws_launch_template" "consul-server-tmpl" {
  name_prefix = "${lookup(var.consul-server, "prefix")}"
  
  image_id = data.aws_ami.consul-server-ami.id
  instance_type = "${lookup(var.consul-server, "instance_type")}"
  
  user_data = data.cloudinit_config.consul-server-cloud-init.rendered

  vpc_security_group_ids = [aws_security_group.consul-server-sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${lookup(var.consul-server, "prefix")}"
      Role = "consul-server"
    }
  }

  monitoring {
    enabled = true
  }
}

resource "aws_autoscaling_group" "consul-server-asg" {
  name_prefix = "${lookup(var.consul-server, "prefix")}"

  target_group_arns = [aws_lb_target_group.consul-server-https-api-tg.arn, aws_lb_target_group.consul-server-https-api-tg-int.arn]

  max_size = "${lookup(var.consul-server, "max_size")}"
  min_size = "${lookup(var.consul-server, "min_size")}"

  vpc_zone_identifier = [for subnet in aws_subnet.nomad-subnet : subnet.id]

  launch_template {
    id = aws_launch_template.consul-server-tmpl.id
    version = "$Latest"
  }
}
