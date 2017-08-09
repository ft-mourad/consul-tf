provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

provider "aws" {
  alias      = "ireland"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "eu-west-1"
}

# Create a web server
resource "aws_instance" "consul_server" {
  provider             = "aws.ireland"
  count = 3
  ami                  = "ami-d7b9a2b1"
  subnet_id            = "subnet-47912220"
  instance_type        = "t2.micro"
  key_name             = "vaultconsul"
  iam_instance_profile = "consul-autodetect"

  tags {
    "Name" = "Consul-Server-${count.index}"
    "Consul" = "AWS"
  }

  connection {
    user        = "ec2-user"
    private_key = "${file("/Users/Mourad/.ssh/vaultconsul.pem")}"
  }

  provisioner "file" {
    source      = "files/ireland/server"
    destination = "~"
  }

  provisioner "remote-exec" {
    inline = [
      # "export AWS_ACCESS_KEY_ID=${var.aws_access_key}",
      # "export AWS_SECRET_KEY=${var.aws_secret_key}",
      # "export AWS_ACCESS_KEY_ID=${var.aws_region}",
      "sudo yum install  -y mysql mysql-server mysql-devel vim git gcc curl unzip",
      # "wget https://releases.hashicorp.com/vault/0.7.3/vault_0.7.3_linux_amd64.zip; unzip vault_0.7.3_linux_amd64.zip; sudo mv vault /bin; rm vault_0.7.3_linux_amd64.zip",
      "wget https://releases.hashicorp.com/consul/0.9.0/consul_0.9.0_linux_amd64.zip; unzip consul_0.9.0_linux_amd64.zip; sudo mv consul /bin; rm consul_0.9.0_linux_amd64.zip",
      "sudo mkdir /etc/consul.d",
      "consul agent -server -node=consul-server-${count.index} -bootstrap-expect=${var.cluster_size} -config-dir=/home/ec2-user/server -retry-join-ec2-tag-key=Consul -retry-join-ec2-tag-value=AWS  &",
      "sleep 10",
    ]
  }
}

# Create a web server
resource "aws_instance" "consul_node" {
  provider             = "aws.ireland"
  count                = 5
  ami                  = "ami-d7b9a2b1"
  subnet_id            = "subnet-47912220"
  instance_type        = "t2.micro"
  key_name             = "vaultconsul"
  iam_instance_profile = "consul-autodetect"

  tags {
    "Name" = "Consul-Node-${count.index}"
    "Consul" = "AWS"
  }

  connection {
    # The default username for our AMI
    user        = "ec2-user"
    private_key = "${file("/Users/Mourad/.ssh/vaultconsul.pem")}"

    # The connection will use the local SSH agent for authentication.
  }

  provisioner "file" {
    source      = "files/ireland/node"
    destination = "~"
  }

  provisioner "remote-exec" {
    inline = [
      # "export AWS_ACCESS_KEY_ID=${var.aws_access_key}",
      # "export AWS_SECRET_KEY=${var.aws_secret_key}",
      # "export AWS_ACCESS_KEY_ID=${var.aws_region}",
      "sudo yum install  -y mysql mysql-server mysql-devel vim git gcc curl unzip",
      # "wget https://releases.hashicorp.com/vault/0.7.3/vault_0.7.3_linux_amd64.zip; unzip vault_0.7.3_linux_amd64.zip; sudo mv vault /bin; rm vault_0.7.3_linux_amd64.zip",
      "wget https://releases.hashicorp.com/consul/0.9.0/consul_0.9.0_linux_amd64.zip; unzip consul_0.9.0_linux_amd64.zip; sudo mv consul /bin; rm consul_0.9.0_linux_amd64.zip",
      "sleep 5",
      "consul agent -node=consul-node-${count.index} -config-dir=/home/ec2-user/node -retry-join-ec2-tag-key=Consul -retry-join-ec2-tag-value=AWS &",
      "sleep 5",
      "echo done"
    ]
  }
}
