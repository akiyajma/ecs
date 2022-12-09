# postgres
resource "aws_ecr_repository" "postgres" {
  name                 = "postgres"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = "true"
  }
}

resource "aws_ecr_lifecycle_policy" "postgres" {
  policy = jsonencode(
    {
      rules = [
        {
          action = {
            type = "expire"
          }
          description  = "Delete images, keeping the five most recent."
          rulePriority = 1
          selection = {
            countNumber = 5
            countType   = "imageCountMoreThan"
            tagStatus   = "any"
          }
        },
      ]
    }
  )
  repository = aws_ecr_repository.postgres.name
}

# puppetdb
resource "aws_ecr_repository" "puppetdb" {
  name                 = "puppetdb"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = "true"
  }
}

resource "aws_ecr_lifecycle_policy" "puppetdb" {
  policy = jsonencode(
    {
      rules = [
        {
          action = {
            type = "expire"
          }
          description  = "Delete images, keeping the five most recent."
          rulePriority = 1
          selection = {
            countNumber = 5
            countType   = "imageCountMoreThan"
            tagStatus   = "any"
          }
        },
      ]
    }
  )
  repository = aws_ecr_repository.puppetdb.name
}

# puppetserver
resource "aws_ecr_repository" "puppetserver" {
  name                 = "puppetserver"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = "true"
  }
}

resource "aws_ecr_lifecycle_policy" "puppetserver" {
  policy = jsonencode(
    {
      rules = [
        {
          action = {
            type = "expire"
          }
          description  = "Delete images, keeping the five most recent."
          rulePriority = 1
          selection = {
            countNumber = 5
            countType   = "imageCountMoreThan"
            tagStatus   = "any"
          }
        },
      ]
    }
  )
  repository = aws_ecr_repository.puppetserver.name
}

# puppetboard
resource "aws_ecr_repository" "puppetboard" {
  name                 = "puppetboard"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = "true"
  }
}

resource "aws_ecr_lifecycle_policy" "puppetboard" {
  policy = jsonencode(
    {
      rules = [
        {
          action = {
            type = "expire"
          }
          description  = "Delete images, keeping the five most recent."
          rulePriority = 1
          selection = {
            countNumber = 5
            countType   = "imageCountMoreThan"
            tagStatus   = "any"
          }
        },
      ]
    }
  )
  repository = aws_ecr_repository.puppetboard.name
}

# r10k
resource "aws_ecr_repository" "r10k" {
  name                 = "r10k"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = "true"
  }
}

resource "aws_ecr_lifecycle_policy" "r10k" {
  policy = jsonencode(
    {
      rules = [
        {
          action = {
            type = "expire"
          }
          description  = "Delete images, keeping the five most recent."
          rulePriority = 1
          selection = {
            countNumber = 5
            countType   = "imageCountMoreThan"
            tagStatus   = "any"
          }
        },
      ]
    }
  )
  repository = aws_ecr_repository.r10k.name
}
