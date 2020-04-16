# INPUTS

variable "project_id" {}
variable "env_name" {}
variable "dns_zone_name" {}
variable "dns_project_id" {}
variable "system_domain_suffix" {}

variable "internal_cidr" {
  default = "10.0.0.0/24"
}
variable "region" {
  default = "us-west1"
}
variable "zone" {
  default = "us-west1-b"
}

# RESOURCES

provider "google" {
  credentials = "${file("account.json")}"
  project = var.project_id
  region = var.region
}

provider "google" {
  alias = "dns"
  credentials = "${file("account.json")}"
  project = var.dns_project_id
  region = var.region
}

resource "google_compute_network" "default" {
  name = var.env_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name = var.env_name
  ip_cidr_range = var.internal_cidr
  network = google_compute_network.default.self_link
}

resource "google_compute_firewall" "default" {
  name = var.env_name
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = ["25555", "22", "2222", "6868", "443", "80", "4443", "6283", "8443", "8844", "8845", "1024-1123", "3333"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [var.env_name]
}

resource "google_compute_address" "default" {
  name = var.env_name
}

resource "google_dns_managed_zone" "default" {
  name        = var.dns_zone_name
  dns_name    = "${var.dns_zone_name}.${var.system_domain_suffix}"
}

resource "google_dns_record_set" "default" {
  provider = google.dns
  name = "*.${var.dns_zone_name}.${var.system_domain_suffix}."
  type = "A"
  ttl = 300

  managed_zone = google_dns_managed_zone.default.name
  rrdatas = [ google_compute_address.default.address ]
}

# OUTPUTS

output "external_ip" {
  value = google_compute_address.default.address
}

output "system_domain" {
  value = "${var.env_name}.${var.system_domain_suffix}"
}

output "network" {
  value = google_compute_network.default.name
}

output "subnetwork" {
  value = google_compute_subnetwork.default.name
}

output "zone" {
  value = var.zone
}

output "tags" {
  value = google_compute_firewall.default.target_tags
}

output "project_id" {
  value = var.project_id
}

output "internal_ip" {
  value = "${cidrhost("${google_compute_subnetwork.default.ip_cidr_range}", 6)}"
}

output "internal_gw" {
  value = "${cidrhost("${google_compute_subnetwork.default.ip_cidr_range}", 1)}"
}

output "internal_cidr" {
  value = google_compute_subnetwork.default.ip_cidr_range
}
