//
// Create a new Managed Kubernetes Node Group.
//
resource "yandex_kubernetes_node_group" "node-group" {
  count = 3
  cluster_id  = yandex_kubernetes_cluster.k8s-regional.id
  name        = "node-group-${count.index}"
  description = "First node group"
#  version     = "1.30"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = [ yandex_vpc_subnet.app-subnet-zones[count.index].id ] 
    }

    resources {
      memory = 2
      cores  = 2
      core_fraction = 50
    }

    boot_disk {
      type = "network-ssd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    #auto_scale {
    #  min     = 1
    #  max     = 3
    #  initial = 2
    #}
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = yandex_vpc_subnet.app-subnet-zones[count.index].zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "sunday"
      start_time = "03:00"
      duration   = "3h"
    }
  }
}
