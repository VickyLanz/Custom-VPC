output "vpc-creation-mode" {
  value = google_compute_network.custom_network
}
output "external_ip" {
  value = google_compute_instance.first_instance.network_interface.0.access_config[0].nat_ip
}