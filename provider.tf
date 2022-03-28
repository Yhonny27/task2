#Configure the Google Cloud Provider
provider "google" {
  project      = "projectx-344700"
  region       = "us-central1"
  zone         = "us-central1-c"
}
data "google_client_config" "provider" {}
provider "kubernetes" {
  host = "https://${google_container_cluster.private-cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.private-cluster.master_auth.0.cluster_ca_certificate)
}
