resource "aws_security_group" "nomad-bootstrap-sg" {
  name = "nomad-bootstrap-sg"
  vpc_id = aws_vpc.nomad-vpc.id
}

resource "aws_security_group_rule" "nomad-bootstrap-ssh" {
  type = "ingress"
  protocol = "TCP"
  from_port = 22
  to_port = 22
  cidr_blocks = ["75.157.3.0/24"]
  security_group_id = aws_security_group.nomad-bootstrap-sg.id
}

resource "aws_security_group_rule" "nomad-bootstrap-egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = -1
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nomad-bootstrap-sg.id
}

resource "aws_iam_policy" "nomad-kraken-bootstrap-policy" {
  name        = "nomad-kraken-bootstrap-policy"
  description = "Provides permissions to get an access to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::soleks-infra",
          "arn:aws:s3:::soleks-infra/*" ]
      },
    ]
  })
}

resource "aws_iam_role" "nomad-kraken-bootstrap-role" {
  name = "nomad-kraken-bootstrap-role"

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

resource "aws_iam_policy_attachment" "nomad-bootstrap-attach" {
  name       = "nomad-bootstrap-attach"
  roles      = [aws_iam_role.nomad-kraken-bootstrap-role.name]
  policy_arn = aws_iam_policy.nomad-kraken-bootstrap-policy.arn
}

resource "aws_iam_instance_profile" "nomad-kraken-bootstrap-profile" {
  name = "nomad-kraken-bootstrap-profile"
  role = aws_iam_role.nomad-kraken-bootstrap-role.name
}

data "aws_ami" "nomad-bootstrap-ami" {
  name_regex = "${lookup(var.nomad-bootstrap, "ami_name")}"
  owners = ["self"]
}

data "cloudinit_config" "bootstrap-cloud-init" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/nomad-base-cloud-init.yaml.tpl", {})
  }
}

resource "aws_instance" "nomad-bootstrap" {
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"

  ami = data.aws_ami.nomad-bootstrap-ami.id
  instance_type = "${lookup(var.nomad-bootstrap, "instance_type")}"

  iam_instance_profile = aws_iam_instance_profile.nomad-kraken-bootstrap-profile.name

  subnet_id = aws_subnet.nomad-subnet-pub[count.index].id

  vpc_security_group_ids = [aws_security_group.nomad-bootstrap-sg.id]

  user_data_base64 = "${data.cloudinit_config.bootstrap-cloud-init.rendered}"

  tags = {
    Name = "${lookup(var.nomad-bootstrap, "prefix")}-${element(lookup(var.nomad-vpc, "availability_zones"), count.index)}"
    Role = "nomad-bootstrap"
  }
}

resource "aws_eip" "nomad-bootstrap-eip" {
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"

  vpc = true

  instance = aws_instance.nomad-bootstrap[count.index].id
}

resource "aws_route53_record" "nomad-bootstrap-resource-record" {
  count = "${length(lookup(var.nomad-vpc, "availability_zones"))}"

  zone_id = data.aws_route53_zone.nomad-dns-zone-public.zone_id

  name = "nomad-bootstrap-${element(lookup(var.nomad-vpc, "availability_zones"), count.index)}"
  type = "A"
  ttl = 60
  records = [aws_eip.nomad-bootstrap-eip[count.index].public_ip]
}
