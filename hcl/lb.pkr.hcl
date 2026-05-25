source "hcloud" "lb" {
  image         = "ubuntu-24.04"
  location      = "nbg1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "lb-{{uuid}}"

  snapshot_labels = {
    app = "lb"
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
    "source.hcloud.lb"
  ]

  provisioner "shell" {
    scripts = [
      "lb.sh"
      "common.sh"
    ]
  }
}
