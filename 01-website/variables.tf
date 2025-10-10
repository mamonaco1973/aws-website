# ---------------------------------------------
# VARIABLE: Domain Name
# ---------------------------------------------
variable "domain_name" {
  description = "The fully-qualified domain name of the Route 53 hosted zone (e.g., mikes-cloud-solutions.org.)"
  type        = string
  default     = "mikes-cloud-solutions.com." # Replace with your domain name
}
