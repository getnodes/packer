source "hcloud" "pritunl" {
  image         = "ubuntu-24.04"
  location      = "nbg1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "pritunl-{{uuid}}"

  snapshot_labels = {
    app = "pritunl"
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
    "source.hcloud.pritunl"
  ]

  provisioner "shell" {
    scripts = [
      "sh/pritunl.sh",
      "sh/common.sh"
    ]
  }
}
