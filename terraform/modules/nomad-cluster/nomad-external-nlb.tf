resource "aws_lb" "nomad-external-lb" {
  name = "${var.nomad-cluster-name}-extlb"
  load_balancer_type = "network"
  internal = false
  subnets = [for subnet in aws_subnet.nomad-subnet-pub : subnet.id]
  enable_cross_zone_load_balancing = true
}

resource "aws_route53_record" "nomad-external-lb-record" {
  zone_id = data.aws_route53_zone.nomad-dns-zone-public.zone_id

  name = "${var.nomad-cluster-name}"
  type = "CNAME"
  ttl = 60
  records = [aws_lb.nomad-external-lb.dns_name]
}

resource "aws_route53_record" "consul-external-lb-record" {
  zone_id = data.aws_route53_zone.nomad-dns-zone-public.zone_id

  name = "${var.consul-cluster-name}"
  type = "CNAME"
  ttl = 60
  records = [aws_lb.nomad-external-lb.dns_name]
}

resource "aws_lb_target_group" "nomad-server-http-api-tg" {
  port  = 4646
  protocol = "TCP"
  vpc_id = aws_vpc.nomad-vpc.id

  preserve_client_ip = true

  health_check {
    port = 4646
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "nomad-server-listener" {
  load_balancer_arn = aws_lb.nomad-external-lb.id
  port = 4646
  protocol = "TCP"
  
  default_action {
    target_group_arn = aws_lb_target_group.nomad-server-http-api-tg.id
    type = "forward"
  }
}

resource "aws_lb_target_group" "consul-server-https-api-tg" {
  port  = 8501
  protocol = "TCP"
  vpc_id = aws_vpc.nomad-vpc.id

  preserve_client_ip = true

  health_check {
    port = 8501
    protocol = "TCP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "consul-server-listener" {
  load_balancer_arn = aws_lb.nomad-external-lb.id
  port = 8501
  protocol = "TCP"
  
  default_action {
    target_group_arn = aws_lb_target_group.consul-server-https-api-tg.id
    type = "forward"
  }
}
