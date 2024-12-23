variable "github_owner" {
  description = "GitHub owner/organisation name"
  type        = string
  default     = "murtaza-u"
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  sensitive   = true
}
