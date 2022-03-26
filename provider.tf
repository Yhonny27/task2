#Configure the Google Cloud Provider
provider "google" {
  project      = "projectx-344700"
  region       = "us-central1"
  zone         = "us-central1-c"
}
data "google_client_config" "provider" {}
# data "google_container_cluster" "my_cluster" {
#   name     = "private-cluster"
#   location = "us-central1"
# }

#provider "kubernetes" {
#  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
#  token = data.google_client_config.provider.access_token
#  cluster_ca_certificate = base64decode(
#    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
#  )
#}
provider "kubernetes" {
  host = "https://${google_container_cluster.private-cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  #cluster_ca_certificate = base64decode(
  #data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate, )
  #client_certificate     = google_container_cluster.private-cluster.master_auth.0.client_certificate 
  #client_key             = google_container_cluster.private-cluster.master_auth.0.client_key
  cluster_ca_certificate = base64decode(google_container_cluster.private-cluster.master_auth.0.cluster_ca_certificate)
}
