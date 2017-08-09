output "Consul Master" {
  value = ["${aws_instance.consul_server_first.public_ip}"]
}

output "Consul Servers" {
  value = ["${aws_instance.consul_server.*.public_ip}"]
}

output "Consul Nodes" {
  value = ["${aws_instance.consul_node.*.public_ip}"]
}
