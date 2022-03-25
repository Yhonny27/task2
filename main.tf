# 1. Create a custom service account to create GKE clusters.
resource "google_service_account" "gke_user" {
  account_id   = "gke-user"
  display_name = "gke User"
}
resource "google_project_iam_binding" "gke_usera" {
  project            = "projectx-344700"
  role               = "roles/gkehub.admin"
  members = [
    "serviceAccount:${google_service_account.gke_user.email}",
  ]
}
resource "google_project_iam_binding" "store_userb" {
  project            = "projectx-344700"
  role               = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${google_service_account.gke_user.email}",
  ]
}
#2. Create VPC network called "demo-network"
resource "google_compute_network" "demo-network" {
  provider = google-beta
  project  = "projectx-344700"
  name = "demo-network"
}
#Private IP
resource "google_compute_global_address" "private-ip-address" {
  provider = google-beta
  project  = "projectx-344700"
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = "projects/projectx-344700/global/networks/demo-network"
}
resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta
  network                 = "projects/projectx-344700/global/networks/demo-network"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private-ip-address.name]
}
#Create subnetwork called demo-subnet
resource "google_compute_subnetwork" "demo-subnet" {
  name     = "demo-subnet"
  region   = "us-central1"
  network  = "projects/projectx-344700/global/networks/demo-network"
  ip_cidr_range  = "10.0.36.0/24"
  private_ip_google_access = true
  secondary_ip_range {
    range_name = "pod"
    ip_cidr_range = "172.16.0.0/16"
  }
  secondary_ip_range {
    range_name ="services"
    ip_cidr_range = "10.0.32.0/22"
  }
}
#3. Create GKE Cluster
resource "google_container_cluster" "private-cluster" {
  name               = "private-cluster"
  location           = "us-central1"
  remove_default_node_pool = true
  initial_node_count = 1

  network    = "projects/projectx-344700/global/networks/demo-network"
  subnetwork = "projects/projectx-344700/regions/us-central1/subnetworks/demo-subnet"

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "10.42.0.0/28"
  }

  master_authorized_networks_config {}

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.demo-subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.demo-subnet.secondary_ip_range[1].range_name
  }
}
#Create the node pool
resource "google_container_node_pool" "cluster_nodes" {
  name       = "cluster-node"
  location   = "us-central1"
  cluster    = google_container_cluster.private-cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_user.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
#5 Create the SQL instance DB
resource "google_sql_database_instance" "instance27" {
  name             = "instance27"
  region           = "us-central1"
  database_version = "MYSQL_5_6"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-n1-standard-1"
    activation_policy = "ALWAYS"
    ip_configuration {
      ipv4_enabled = true
      private_network = "projects/projectx-344700/global/networks/demo-network"
    }
  }
  deletion_protection  = "false"
}
resource "google_sql_database" "databaseforghost" {
  name     = "databaseforghost"
  instance = google_sql_database_instance.instance27.name
  charset = "UTF8"
}
resource "google_sql_user" "user" {
  name= "root"
  instance = google_sql_database_instance.instance27.name
  password = "toor"
}

#Create Cloud Storage and Bucket to backup DB
resource "google_storage_bucket" "mysql_backup_task2" {
  name          = "mysql_backup_task2"
  location      = "US"
  force_destroy = true
  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }
}
# 6. Create a namespace, name it as <your first name>_<your last name>
# 7. Create a deployment with the ghost image with 2 replicas.
resource "kubernetes_deployment" "ghost-image" {
  metadata {
    name =      "ghost-image"
    namespace = "yhonathan-camacho"
    labels = {
      test = "Demo"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "ghost-image"
      }
    }
    template {
      metadata {
      name =      "ghost-image"
        labels = {
          app = "ghost-image"
        }
      }
      spec {
      
      node_selector = null
        
        container {
          image = "ghost:4-alpine"
          name  = "ghost-image"
        
        port {

          container_port = 2368
          protocol       = "TCP"

      }
          resources {

            requests = {
              
              cpu    = "50m"
              memory = "50Mi"
              
            }
          
            limits = {
              cpu    = "1000m"
              memory = "200Mi"
            }
          }

          liveness_probe {

              tcp_socket {

                port = 2368

              }

              initial_delay_seconds = 15
              period_seconds        = 15

          }

          readiness_probe {

            tcp_socket {

                port = 2368

            }

              initial_delay_seconds = 15
              period_seconds        = 15

          }
          
          env {

              name  = "database__client"
              value = "mysql"
          }

          env {

              name  = "database__connection__host"
              value = "databaseforghost"
          }

          env {

              name  = "database__connection__user"
              value = "root"

          }

          env {

              name  = "database__connection__password"
              value = "toor"

          }

          env {

              name  = "database__connection__database"
              value = "instance27"

          }

          env {

              name  = "url"
              value = "https://localhost:2368"

              }

          volume_mount {

              name       = "content"
              mount_path = "/var/lib/ghost/content"

              }
        }

          volume {

              name = "content"

              nfs {

                  server = "nfs.default.svc.cluster.local"
                  path   = "/exports/${var.x}"

                    }
                }
            }
        }
    }
}

# 8. Create a service and ingress for the previous deployment. Test it in your browser.
#Service
resource "kubernetes_service" "service" {

    metadata {

        name      = "ghost-image"
        namespace = "yhonathan-camacho"

        labels = {

            app = "ghost-image"

        }

    }

    spec {

        type = "LoadBalancer"

        selector = {

            app = "ghost-image"

        }

        port {

            port        = 2368
            target_port = 2368
            protocol    = "TCP"

        }

    }

}

#Ingress
resource "kubernetes_ingress" "example_ingress" {
  metadata {
    name = "ghost-image"
  }

  spec {
    backend {
      service_name = "myapp-1"
      service_port = 8080
    }

    rule {
      http {
        path {
          backend {
            service_name = "myapp-1"
            service_port = 8080
          }

          path = "/app1/*"
        }

        path {
          backend {
            service_name = "myapp-2"
            service_port = 8080
          }

          path = "/app2/*"
        }
      }
    }

    tls {
      secret_name = "tls-secret"
    }
  }
}
# 9. Create a Cron job to backup (once a day) the database you created in the previous step and send to a storage bucket. (Use CloudSQL Proxy, it also has a Docker image):
# You can authenticate to CloudSQL using:
# a. Store the CloudSQL data (instance_name, user, password) in Kubernetes
resource "kubernetes_cron_job_v1" "demo" {
  metadata {
    name = "ghost-image"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "1 0 * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 10
    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            container {
              name    = "ghost-image"
              image   = "ghost:4-alpine"
              command = ["/bin/sh", "-c", "date; echo Hello from the Kubernetes cluster"]
              #command = [cp databaseforghost gs://mysql_backup_task2]
            }
          }
        }
      }
    }
  }
}

# 10. Deploy a Jenkins server using a Bitnami image from Google Cloud Marketplace
# 11. Install the requirement plugins (Terraform, git, etc)
