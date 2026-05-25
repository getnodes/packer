source "hcloud" "k3s_lb_backup" {
  image         = "ubuntu-24.04"
  location      = "nbg1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "k3s-lb-backup-{{uuid}}"

  snapshot_labels = {
    app = "k3s-lb-backup"
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
    "source.hcloud.k3s_lb_backup"
  ]

  provisioner "shell" {
    scripts = [
      "k3s-lb-backup.sh"
      "common.sh"
    ]
  }
}
