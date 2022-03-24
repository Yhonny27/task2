terraform{
    backend "gcs" {
        bucket = "terraform-gcs-demo"
        prefix = "terraform/task2"
        credentials = "terraform-sa.json"
    }
}