source "hcloud" "pritunl" {
  image         = "ubuntu-24.04"
  location      = "fsn1"
  server_type   = "cpx22"
  ssh_username  = "root"
  snapshot_name = "pritunl-{{uuid}}"

  snapshot_labels = {
    app = "pritunl"
  }
}

build {
  sources = [
    "source.hcloud.pritunl"
  ]

  provisioner "shell" {
    scripts = [
      "pritunl.sh"
    ]
  }
}
