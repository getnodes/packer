source "hcloud" "k3s_agent" {
  image         = "ubuntu-24.04"
  location      = "nbg1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "k3s-agent-{{uuid}}"

  snapshot_labels = {
    app = "k3s-agent"
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
    "source.hcloud.k3s_agent"
  ]

  provisioner "shell" {
    scripts = [
      "k3s-agent.sh"
      "common.sh"
    ]
  }
}
