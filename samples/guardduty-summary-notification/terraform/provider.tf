provider "aws" {
  profile = "security-account"
  region  = "ap-northeast-1"

  default_tags {
    tags = {
      Project = "Security"
      Env     = "Prod"
    }
  }
}
