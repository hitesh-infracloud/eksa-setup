provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "allow-ssh" {
  name        = "allow-ssh"
  description = "allow ssh to cli users"

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags= {
    Name = "allow-ssh"
  }
}

resource "aws_instance" "Demo" {
  ami           = "ami-0da59f1af71ea4ad2"
  instance_type = "t2.micro"
  key_name = "eksa-admin"
  security_groups= ["allow-ssh"]
  tags = {
    Name = "eksa_admin"
  }
}

resource "null_resource" "copy_files" {
 triggers = {
  instance_id = aws_instance.Demo.id
 }

  provisioner "remote-exec" {
      connection {
      type        = "ssh"
      host        = aws_instance.Demo.public_ip
      user        = "ec2-user"
      private_key = file("~/.aws/key-pairs/eksa-admin.pem")
    }

      inline = ["echo 'connected!'"]
  }

  provisioner "local-exec" {
    command = "chmod +x local-exec.sh; ./local-exec.sh ${aws_instance.Demo.public_ip} /var/lib/cloud/instance/boot-finished 600"
  }
 
}
