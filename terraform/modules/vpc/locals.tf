locals {
  bTags = {
    Project     = var.project
    Environment = var.environment
  }
  pTags = "${var.project}-${var.environment}"
}