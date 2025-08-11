resource "aws_lb" "nomad-internal-lb" {
  name = "${var.nomad-cluster-name}-intlb"
  load_balancer_type = "network"
  internal = true
  subnets = [for subnet in aws_subnet.nomad-subnet : subnet.id]
  enable_cross_zone_load_balancing = true
}

resource "aws_route53_record" "nomad-internal-lb-record" {
  zone_id = data.aws_route53_zone.nomad-dns-zone.zone_id

  name = "${var.nomad-cluster-name}"
  type = "CNAME"
  ttl = 60
  records = [aws_lb.nomad-internal-lb.dns_name]
}

resource "aws_route53_record" "consul-internal-lb-record" {
  zone_id = data.aws_route53_zone.nomad-dns-zone.zone_id

  name = "${var.consul-cluster-name}"
  type = "CNAME"
  ttl = 60
  records = [aws_lb.nomad-internal-lb.dns_name]
}

resource "aws_lb_target_group" "nomad-server-http-api-tg-int" {
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

resource "aws_lb_listener" "nomad-server-listener-int" {
  load_balancer_arn = aws_lb.nomad-internal-lb.id
  port = 4646
  protocol = "TCP"
  
  default_action {
    target_group_arn = aws_lb_target_group.nomad-server-http-api-tg-int.id
    type = "forward"
  }
}

resource "aws_lb_target_group" "consul-server-https-api-tg-int" {
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

resource "aws_lb_listener" "consul-server-listener-int" {
  load_balancer_arn = aws_lb.nomad-internal-lb.id
  port = 8501
  protocol = "TCP"
  
  default_action {
    target_group_arn = aws_lb_target_group.consul-server-https-api-tg-int.id
    type = "forward"
  }
}
