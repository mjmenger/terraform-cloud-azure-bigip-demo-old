resource "random_id" "server" {
  keepers = {
    ami_id = 1
  }

  byte_length = 8
}

resource "random_password" "bigippassword" {
  length = 16
  special = true
  override_special = "_%@"
}

