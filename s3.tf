locals {
  bucket = {
    name = "ecs-puppet"
    object = {
      ssl   = "puppetserver-config/"
      ca    = "puppetserver-ca/"
      data = "puppetserver-data/"
      code = "puppetserver-code/"
    }
  }
}

resource "aws_s3_bucket" "ecs-puppet" {
  bucket = local.bucket.name
  #region = "ap-northeast-1"
  tags = {
    Name = local.bucket.name
  }
}

resource "aws_s3_bucket_versioning" "ecs-puppet" {
  bucket = aws_s3_bucket.ecs-puppet.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "ecs-puppet" {
  bucket = aws_s3_bucket.ecs-puppet.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "ecs-puppet" {
  for_each = local.bucket.object
  bucket   = aws_s3_bucket.ecs-puppet.id
  key      = each.value
}