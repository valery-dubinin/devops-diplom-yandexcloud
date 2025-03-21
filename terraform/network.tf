resource "yandex_vpc_network" "app-net" {
  name = "app-net"
}

resource "yandex_vpc_subnet" "app-subnet-zones" {
  count = 3
  name = "subnet-${var.subnet-zones[count.index]}"
  zone = "${var.subnet-zones[count.index]}"
  network_id = "${yandex_vpc_network.app-net.id}"
  v4_cidr_blocks = [ "${var.cidr.cidr[count.index]}" ]
}