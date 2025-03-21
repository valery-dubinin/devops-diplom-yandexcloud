// Create SA
resource "yandex_iam_service_account" "sa-diplom" {
  name = "sa-diplom"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "diplom-editor" {
  folder_id = var.folder_id
  role = "editor"
  member = "serviceAccount:${yandex_iam_service_account.sa-diplom.id}"
  depends_on = [ yandex_iam_service_account.sa-diplom ]
}

//Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa-diplom.id
  description = "static access key"
}

//Use keys to create bucket
resource "yandex_storage_bucket" "dubinin-bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "dubinin-bucket"
  acl = "private"
  force_destroy = true
  depends_on = [ yandex_resourcemanager_folder_iam_member.diplom-editor ]
}

//Create "local_file" for shared_credentials_files
resource "local_file" "credfile" {
  content = <<EOT
[default]
aws_access_key_id = ${yandex_iam_service_account_static_access_key.sa-static-key.access_key}
aws_secret_access_key = ${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}
EOT
  filename = "../credfile.key"
}