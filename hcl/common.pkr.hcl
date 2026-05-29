source "hcloud" "common" {
  image         = "ubuntu-24.04"
  location      = "nbg1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "common-{{uuid}}"

  snapshot_labels = {
    app = "common"
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
    "source.hcloud.common"
  ]

  provisioner "shell" {
    scripts = [
      "sh/common.sh"
    ]
  }
}
