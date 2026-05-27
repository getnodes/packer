source "hcloud" "base" {
  image         = "ubuntu-24.04"
  location      = "nbg1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "base-{{uuid}}"

  snapshot_labels = {
    app = "base"
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
    "source.hcloud.base"
  ]

  provisioner "shell" {
    scripts = [
      "base.sh"
    ]
  }
}
