source "hcloud" "harbor" {
  image         = "ubuntu-24.04"
  location      = "nbg1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "harbor-{{uuid}}"

  snapshot_labels = {
    app = "harbor"
  }

  user_data = <<-EOF
  #cloud-config
  growpart:
  mode: "off"
  resize_rootfs: false
  EOF
}

build {
  sources = [
    "source.hcloud.harbor"
  ]

  provisioner "shell" {
    scripts = [
      "harbor.sh"
      "common.sh"
    ]
  }
}
