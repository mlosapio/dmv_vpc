provider "aws" {
	region = "us-east-1"
}

resource "aws_vpc" "dmz" {
    cidr_block = "${var.peer_vpc_cidr}"
}

data "aws_availability_zones" "available" {}

data "aws_vpc" "main" {
    id = "${var.main_vpc_id}"
}

data "template_file" "proxy" {
    template = "${file("proxy.tpl")}"
}


resource "aws_subnet" "subnet1" {
    vpc_id            = "${aws_vpc.dmz.id}"
    cidr_block        = "${cidrsubnet(aws_vpc.dmz.cidr_block, 4, 1)}"
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
}


resource "aws_subnet" "subnet2" {
    vpc_id            = "${aws_vpc.dmz.id}"
    cidr_block        = "${cidrsubnet(aws_vpc.dmz.cidr_block, 4, 2)}"
    availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_vpc_peering_connection" "peer_home" {
    peer_vpc_id = "${data.aws_vpc.main.id}"
    vpc_id      = "${aws_vpc.dmz.id}"
    auto_accept = true
}

resource "aws_route_table" "dmz" {
    vpc_id = "${aws_vpc.dmz.id}"
    route {
        cidr_block                = "${data.aws_vpc.main.cidr_block}"
        vpc_peering_connection_id = "${aws_vpc_peering_connection.peer_home.id}"
    }
}

resource "aws_route_table_association" "a" {
    subnet_id = "${aws_subnet.subnet1.id}"
    route_table_id = "${aws_route_table.dmz.id}"
}

resource "aws_route_table_association" "b" {
    subnet_id = "${aws_subnet.subnet2.id}"
    route_table_id = "${aws_route_table.dmz.id}"
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.dmz.id}"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dmz_proxy1" {
    ami                    = "ami-c58c1dd3"
    instance_type          = "t2.micro"
    key_name               = "memsqlcloud"
    vpc_security_group_ids = [ "${aws_security_group.allow_all.id}" ]
    subnet_id              = "${aws_subnet.subnet1.id}"
    source_dest_check      = false
    private_ip             = "${cidrhost(aws_subnet.subnet1.cidr_block, 5)}"
    user_data              = "${data.template_file.proxy.rendered}"
    tags {
       Name = "DMZ PROXY 1"
    }
}
