packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

source "hcloud" "pritunl" {
  image         = "ubuntu-24.04"
  location      = "fsn1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "pritunl-{{uuid}}"
}

build {
  sources = [
    "source.hcloud.pritunl"
  ]

  provisioner "shell" {
    scripts = [
      "run.sh"
    ]
  }
}
