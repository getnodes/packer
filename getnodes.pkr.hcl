packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

source "hcloud" "getnodes" {
  image         = "ubuntu-24.04"
  location      = "nbg1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "getnodes-{{uuid}}"
  user_data     = file("getnodes.yaml")

  snapshot_labels = {
    app = "getnodes"
  }
}

build {
  sources = [
    "source.hcloud.getnodes"
  ]

  provisioner "shell" {
    scripts = [
      "getnodes.sh"
    ]
  }
}
