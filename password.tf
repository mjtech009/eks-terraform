#--> Password
resource "random_string" "db_password" {
  length           = 16
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
