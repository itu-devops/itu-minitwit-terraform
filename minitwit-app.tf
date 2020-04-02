# resource "digitalocean_floating_ip"

# create cloud vm
resource "digitalocean_droplet" "minitwit-app" {
  # wait for mysql db to be created so we can grab the ip address
  depends_on = [digitalocean_droplet.minitwit-mysql]

  # number of vms to create
  count = 2

  image = "docker-18-04"
  name = "minitwit-app"
  region = var.region
  size = "1gb"
  # add public ssh key so we can access the machine
  ssh_keys = [digitalocean_ssh_key.minitwit.fingerprint]

  # specify a ssh connection
  connection {
    user = "root"
    host = self.ipv4_address
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }

  # scp file to server
  provisioner "file" {
    source = "docker-compose/minitwit-app-docker-compose.yml"
    destination = "/root/docker-compose.yml"
  }

  # start docker-compose on the new server
  provisioner "remote-exec" {
    inline = [
      "ufw allow 5000",
      "echo 'DB_HOST=${digitalocean_droplet.minitwit-mysql.ipv4_address}' > /root/app.env",
      "docker-compose up -d --quiet-pull"
    ]
  }
}

# output ip address
output "minitwit-app-ip-address" {
  value = digitalocean_droplet.minitwit-app.*.ipv4_address
}
