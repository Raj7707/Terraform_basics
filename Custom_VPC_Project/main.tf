#1. Create a VPC
#2. Create Internet Gateway
#3. Create costum route table
#4. Create Subnet
#5. associate subnet with custom route table
#6. Create security group that allows some ports such as 22, 80,etc
#7. Create a network interface with an ip in the subnet created
#8. Assign an elastic IP to the network interface created
#9. create ubuntu server
# 

provider "aws" {
    region = "us-east-1"
    access_key = "AKIA4QVSLQVAAWGWUYKL"
    secret_key = "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"
}

resource "aws_vpc" "VPC_1" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "production"
    }
}

resource "aws_internet_gateway" "gw_1" {
    vpc_id = aws_vpc.VPC_1.id
    
    tags = {
        Name = "gw"
    }
}

resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.VPC_1.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw_1.id

    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.gw_1.id
    }

    tags = {
        Name = "Route Table"
    }

}

resource "aws_subnet" "subnet_1" {
    vpc_id = aws_vpc.VPC_1.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "prod-subnet"
    }
  
}

resource "aws_route_table_association" "Ass" {
    subnet_id = aws_subnet.subnet_1.id
    route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_access" {
    name = "allow_web_traffic"
    description = "allow web inbound traffic"
    vpc_id = aws_vpc.VPC_1.id

    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_Web"
    }
  
}

resource "aws_network_interface" "web-server_NI" {
    subnet_id = aws_subnet.subnet_1.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.allow_access.id]

  
}

resource "aws_eip" "eip_1" {
    vpc = true
    network_interface = aws_network_interface.web-server_NI.id
    associate_with_private_ip = "10.0.1.50"
    depends_on = [aws_internet_gateway.gw_1]
}

resource "aws_instance" "ubuntu_web_server" {
    ami = "ami-04505e74c0741db8d"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "First EC2 instance"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server_NI.id
      
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo My first web server > /var/www/html/index.html'
                EOF
    
    tags = {
        Name="First_web_server"

    }

  
}

