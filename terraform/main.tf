terraform {
  backend "gcs" {
    bucket = "devops-joepop-storybooks-terraform"
    prefix = "/state/jp-storybooks"
  }
}
