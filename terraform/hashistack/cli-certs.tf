resource "local_file" "cacert" {
  count             = var.cert_path == "" ? 0 : 1
  sensitive_content = module.hashistack.nomad_cacert
  filename          = "${var.cert_path}/nomad/nomad-ca.pem"
}

resource "local_file" "cli_cert" {
  count             = var.cert_path == "" ? 0 : 1
  sensitive_content = module.hashistack.nomad_cli_cert
  filename          = "${var.cert_path}/nomad/cli.pem"
}

resource "local_file" "cli_key" {
  count             = var.cert_path == "" ? 0 : 1
  sensitive_content = module.hashistack.nomad_cli_key
  filename          = "${var.cert_path}/nomad/cli-key.pem"
}

resource "null_resource" "nomad-pfx" {
  count = var.cert_path == "" ? 0 : 1
  triggers = {
    files = join(",", [local_file.cli_cert[0].sensitive_content, local_file.cli_key[0].sensitive_content])
  }

  provisioner "local-exec" {
    command     = "openssl pkcs12 -inkey cli-key.pem -in cli.pem -export -out cli-nomad.pfx -passout pass:${var.ssl_password}"
    working_dir = "${var.cert_path}/nomad"
  }
}

resource "local_file" "cacert_consul" {
  count             = var.cert_path == "" ? 0 : 1
  sensitive_content = module.hashistack.consul_cacert
  filename          = "${var.cert_path}/consul/consul-ca.pem"
}

resource "local_file" "cli_cert_consul" {
  count             = var.cert_path == "" ? 0 : 1
  sensitive_content = module.hashistack.consul_cli_cert
  filename          = "${var.cert_path}/consul/cli.pem"
}

resource "local_file" "cli_key_consul" {
  count             = var.cert_path == "" ? 0 : 1
  sensitive_content = module.hashistack.consul_cli_key
  filename          = "${var.cert_path}/consul/cli-key.pem"
}

resource "null_resource" "consul-pfx" {
  count = var.cert_path == "" ? 0 : 1
  triggers = {
    files = join(",", [local_file.cli_cert_consul[0].sensitive_content, local_file.cli_key_consul[0].sensitive_content])
  }

  provisioner "local-exec" {
    command     = "openssl pkcs12 -inkey cli-key.pem -in cli.pem -export -out cli-consul.pfx -passout pass:${var.ssl_password}"
    working_dir = "${var.cert_path}/consul"
  }
}
