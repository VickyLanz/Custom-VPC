provider "google" {
  project = var.project_id
  region = var.region
  zone = var.zone
}

resource "google_compute_network" "custom_network" {

  name = "custom-vpc"
  auto_create_subnetworks = false
  mtu = 1460

}
resource "google_compute_firewall" "custom_allow_http" {
  depends_on = [google_compute_network.custom_network]
  name    = "custom-allow-http"
  network = google_compute_network.custom_network.self_link
  allow {
    protocol = "tcp"
    ports = ["80"]
  }
  allow {
    protocol = "tcp"
    ports = ["443"]
  }
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "custom_allow_ping" {
  depends_on = [google_compute_network.custom_network]
  name    = "custom-allow-ping"
  network = google_compute_network.custom_network.self_link
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "custom_allow_internal" {
depends_on = [google_compute_network.custom_network]
  name    = "custom-allow-internal"
  network = google_compute_network.custom_network.self_link
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["10.128.0.0/9"]

}
resource "google_compute_firewall" "custom_allow_rdp" {
depends_on = [google_compute_network.custom_network]
  name    = "custom-allow-rdp"
  network = google_compute_network.custom_network.self_link
  allow {
    protocol = "tcp"
    ports = ["3389"]
  }
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "custom_allow_ssh" {
depends_on = [google_compute_network.custom_network]
  name    = "custom-allow-ssh"
  network = google_compute_network.custom_network.self_link
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_subnetwork" "custom_subnet_1" {
depends_on = [google_compute_network.custom_network]
  ip_cidr_range = "10.128.0.0/20"
  name          = "custom-subnet"
  network       = google_compute_network.custom_network.self_link
  region = "us-central1"
}

resource "google_compute_instance" "first_instance" {
  depends_on = [google_compute_subnetwork.custom_subnet_1,google_compute_firewall.custom_allow_internal,google_compute_firewall.custom_allow_ping,google_compute_firewall.custom_allow_rdp,google_compute_firewall.custom_allow_ssh]
  machine_type = "e2-medium"
  name         = "infor-instance"
  tags = ["http-server","https-server"]
  metadata = {
      ssh-keys="${var.user}:${file(var.public_key)}"
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = google_compute_network.custom_network.self_link
    subnetwork = google_compute_subnetwork.custom_subnet_1.self_link
    access_config {

    }
  }
}

resource "null_resource" "remote_exec" {
  connection {
    host = google_compute_instance.first_instance.network_interface.0.access_config[0].nat_ip
    type = "ssh"
    user = var.user
    private_key ="${file(var.privatekeypath)}"
     timeout = "180s"

  }
  provisioner "file" {
    source ="${var.path}"
    destination ="/home/${var.user}/script.sh"
  }
  provisioner "remote-exec" {

    inline = [
    "cd /home/${var.user}/",
      "sudo chmod +x script.sh",
      "./script.sh"
    ]
  }
}