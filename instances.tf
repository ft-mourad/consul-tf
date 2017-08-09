provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

# Create a web server
resource "aws_instance" "consul_server_first" {
  ami           = "ami-d7b9a2b1"
  subnet_id     = "subnet-47912220"
  instance_type = "t2.micro"
  key_name      = "vaultconsul"
  connection {
    # The default username for our AMI
    user        = "ec2-user"
    private_key = "${file("/Users/Mourad/.ssh/vaultconsul.pem")}"

    # The connection will use the local SSH agent for authentication.
  }
  provisioner "remote-exec" {
    inline = ["sudo yum install  -y mysql mysql-server mysql-devel vim git gcc curl unzip",
      "wget https://releases.hashicorp.com/vault/0.7.3/vault_0.7.3_linux_amd64.zip; unzip vault_0.7.3_linux_amd64.zip; sudo mv vault /bin; rm vault_0.7.3_linux_amd64.zip",
      "wget https://releases.hashicorp.com/consul/0.9.0/consul_0.9.0_linux_amd64.zip; unzip consul_0.9.0_linux_amd64.zip; sudo mv consul /bin; rm consul_0.9.0_linux_amd64.zip",
      "sudo mkdir /etc/consul.d",
      "consul agent -server -node=consul-server-0 -bootstrap-expect=3 -data-dir=/tmp/consul -config-dir=/etc/consul.d &",
      "sleep 10",
    ]
  }
}

# Create a web server
resource "aws_instance" "consul_server" {
  count         = 2
  depends_on    = ["aws_instance.consul_server_first"]
  ami           = "ami-d7b9a2b1"
  subnet_id     = "subnet-47912220"
  instance_type = "t2.micro"
  key_name      = "vaultconsul"

  connection {
    # The default username for our AMI
    user        = "ec2-user"
    private_key = "${file("/Users/Mourad/.ssh/vaultconsul.pem")}"

    # The connection will use the local SSH agent for authentication.
  }

  provisioner "remote-exec" {
    inline = ["sudo yum install  -y mysql mysql-server mysql-devel vim git gcc curl unzip",
      "wget https://releases.hashicorp.com/vault/0.7.3/vault_0.7.3_linux_amd64.zip; unzip vault_0.7.3_linux_amd64.zip; sudo mv vault /bin; rm vault_0.7.3_linux_amd64.zip",
      "wget https://releases.hashicorp.com/consul/0.9.0/consul_0.9.0_linux_amd64.zip; unzip consul_0.9.0_linux_amd64.zip; sudo mv consul /bin; rm consul_0.9.0_linux_amd64.zip",
      "sudo mkdir /etc/consul.d",
      "consul agent -server -node=consul-server-${count.index+1} -data-dir=/tmp/consul -config-dir=/etc/consul.d &",
      "sleep 5",
      "consul join ${aws_instance.consul_server_first.public_ip}",
    ]
  }
}

# Create a web server
resource "aws_instance" "consul_node" {
  count         = 5
  ami           = "ami-d7b9a2b1"
  subnet_id     = "subnet-47912220"
  instance_type = "t2.micro"

  key_name = "vaultconsul"

  connection {
    # The default username for our AMI
    user        = "ec2-user"
    private_key = "${file("/Users/Mourad/.ssh/vaultconsul.pem")}"

    # The connection will use the local SSH agent for authentication.
  }

  provisioner "remote-exec" {
    inline = ["sudo yum install  -y mysql mysql-server mysql-devel vim git gcc curl unzip",
      "wget https://releases.hashicorp.com/vault/0.7.3/vault_0.7.3_linux_amd64.zip; unzip vault_0.7.3_linux_amd64.zip; sudo mv vault /bin; rm vault_0.7.3_linux_amd64.zip",
      "wget https://releases.hashicorp.com/consul/0.9.0/consul_0.9.0_linux_amd64.zip; unzip consul_0.9.0_linux_amd64.zip; sudo mv consul /bin; rm consul_0.9.0_linux_amd64.zip",
      "consul agent -node=consul-node--${count.index} -data-dir=/tmp/consul &",
      "sleep 10",
      "consul join ${aws_instance.consul_server_first.public_ip}",
    ]
  }
}
