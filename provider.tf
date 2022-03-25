#Configure the Google Cloud Provider
provider "google" {
  project      = "projectx-344700"
  region       = "us-central1"
  zone         = "us-central1-c"
}

  provider "kubernetes" {
  host = "https://${google_container_cluster.private-cluster.endpoint}"
  client_certificate     = google_container_cluster.private-cluster.master_auth.0.client_certificate 
  client_key             = google_container_cluster.private-cluster.master_auth.0.client_key
  cluster_ca_certificate = base64decode(google_container_cluster.private-cluster.master_auth.0.cluster_ca_certificate)
}
