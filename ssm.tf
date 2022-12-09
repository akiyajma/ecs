###
# Puppet
###
resource "aws_ssm_parameter" "puppet_postgres_user" {
  name        = "/puppet/user"
  value       = "dummy"
  type        = "SecureString"
  description = "Postgres user for puppet"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "puppet_postgres_password" {
  name        = "/puppet/password"
  value       = "dummy"
  type        = "SecureString"
  description = "Postgres user for puppet"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "puppet_postgres_db" {
  name        = "/puppet/db"
  value       = "dummy"
  type        = "SecureString"
  description = "Postgres user for puppet"

  lifecycle {
    ignore_changes = [value]
  }
}