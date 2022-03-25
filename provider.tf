#Configure the Google Cloud Provider
provider "google" {
  project      = "projectx-344700"
  region       = "us-central1"
  zone         = "us-central1-c"
}
provider "kubernetes" {

    config_path    = "~/.kube/config"
    config_context = "google_container_cluster.private-cluster.name"
    host           = data.google_container_cluster.cluster.endpoint
    insecure       = true

}
data "google_container_cluster" "cluster" {

    name     = "private-cluster"
    location = "us-central1"

}
