data "aws_route53_zone" "nomad-dns-zone-public" {
  name = var.nomad-dns-zone
  private_zone = false
}

data "aws_route53_zone" "nomad-dns-zone-private" {
  name = var.nomad-dns-zone
  private_zone = true
}
