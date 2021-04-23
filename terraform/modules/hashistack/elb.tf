resource "aws_elb" "nomad_server" {
  name    = "${var.stack_name}-nomad-server"
  subnets = distinct(data.aws_subnet_ids.nomad.ids)
  // availability_zones = distinct(values(aws_instance.nomad_server)[*].availability_zone)
  internal     = false
  instances    = values(aws_instance.nomad_server)[*].id
  idle_timeout = 360

  listener {
    instance_port      = 4646
    instance_protocol  = "tcp"
    lb_port            = 4646
    lb_protocol        = "tcp"
  }
  
  listener {
    instance_port     = 8501
    instance_protocol = "tcp"
    lb_port           = 8501
    lb_protocol       = "tcp"
  }
  security_groups = [aws_security_group.server_lb.id]
}

resource "aws_elb" "nomad_client" {
  name    = "${var.stack_name}-nomad-client"
  subnets = distinct(data.aws_subnet_ids.nomad.ids)
  // availability_zones = distinct(values(aws_instance.nomad_server)[*].availability_zone)
  internal = false
  listener {
    instance_port      = 8501
    instance_protocol  = "tcp"
    lb_port            = 8501
    lb_protocol        = "tcp"
  }
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  listener {
    instance_port     = 9090
    instance_protocol = "http"
    lb_port           = 9090
    lb_protocol       = "http"
  }
  listener {
    instance_port     = 3000
    instance_protocol = "http"
    lb_port           = 3000
    lb_protocol       = "http"
  }
  listener {
    instance_port     = 8081
    instance_protocol = "http"
    lb_port           = 8081
    lb_protocol       = "http"
  }

  // health_check {
  //   healthy_threshold   = 8
  //   unhealthy_threshold = 2
  //   timeout             = 3
  //   target              = "TCP:8081"
  //   interval            = 30
  // }

  security_groups = [aws_security_group.client_lb.id]
}