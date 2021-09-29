provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "Datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "vsanDatastore"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Wells"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_content_library" "os" {
  name = "OS"
}

data "vsphere_content_library_item" "ubuntu2004" {
  name       = "ubuntu20.04"
  library_id = data.vsphere_content_library.os.id
  type       = "vm-template"
}

resource "vsphere_virtual_machine" "vm" {
  for_each = toset( ["sandbox01", "sandbox02", "sandbox03", "jumpbox"] )
  name     = each.key

  datastore_id     = data.vsphere_datastore.datastore.id
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id

  num_cpus          = 2
  memory            = 4096
  guest_id          = "other3xLinux64Guest"
  nested_hv_enabled = true

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label = "disk0"
    size  = 50
  }
  cdrom {
    client_device = true
  }
  clone {
    template_uuid = data.vsphere_content_library_item.ubuntu2004.id

    #		customize {
    #      linux_options {
    #        host_name = "sandbox02"
    #        domain    = "udcp.run"
    #      }
    #`		      network_interface {
    #`		        ipv4_address = "10.9.8.179"
    #`		        ipv4_netmask = 23
    #`						dns_server_list = ["10.9.8.180"]
    #`		      }
    #`		
    #`		      ipv4_gateway = "10.9.8.1"
    #		}
  }
  vapp {
    properties = {
      "public-keys" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClNV5DBMYmOo5pYMpYE0PzXAFlLbYT46s6a7sGZdr9FIecJakrTtPVm6Po3uFL6qURi6uRQ8VsgeZGzZWWft8yJs1JdTcem8+KIiCenisTT7m9dRaX3EMdvhHyDtFGPSdGSq+blvgKo+HaHUem+Sx8R1lZAESzlZHjCwDxpZc5F/BkB4Jn+WiRgTeMwavOp0FJedNraLwZIHJ9h4kKV5uxIt3VgD5pHMotzjGJXDd2+jrcX6I/gQ/Cq1mXtvIMRoy72vpwF0r2knt1DrOOGi/Z029ZiPbQJl8HjbQSx/7kYPlw+ZI5W5afMSlwcs8qb3SR5ofF06gUftb3Uq/ziD2j"
      "hostname"    = "sandbox02"
    }
  }
}

