variable "oci_profile" {
  description = "Profile name in ~/.oci/config."
  type        = string
  default     = "DEFAULT"
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID. Used to discover availability domains."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID where the VCN and instance are created."
  type        = string
}

variable "region" {
  description = "OCI region. Keep this in Canada for Phase 1."
  type        = string
  default     = "ca-toronto-1"

  validation {
    condition     = can(regex("^ca-", var.region))
    error_message = "Phase 1 requires a Canadian region (ca-toronto-1 or ca-montreal-1)."
  }
}

variable "availability_domain" {
  description = "Optional availability domain name. Empty means the first AD."
  type        = string
  default     = ""
}

variable "instance_name" {
  description = "Display name for the instance."
  type        = string
  default     = "dev-platform-1"
}

variable "shape" {
  description = "Compute shape. Always Free A1 is VM.Standard.A1.Flex."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "OCPUs for the A1 instance. Always Free caps this at 2."
  type        = number
  default     = 2

  validation {
    condition     = var.ocpus > 0 && var.ocpus <= 2
    error_message = "Always Free A1 allows at most 2 OCPUs."
  }
}

variable "memory_gb" {
  description = "Memory in GB for the A1 instance. Always Free caps this at 12."
  type        = number
  default     = 12

  validation {
    condition     = var.memory_gb > 0 && var.memory_gb <= 12
    error_message = "Always Free A1 allows at most 12 GB of memory."
  }
}

variable "boot_volume_gb" {
  description = "Boot volume size in GB. Minimum 50; total Always Free block storage is 200 GB."
  type        = number
  default     = 100

  validation {
    condition     = var.boot_volume_gb >= 50 && var.boot_volume_gb <= 200
    error_message = "Boot volume must be between 50 and 200 GB."
  }
}

variable "ssh_public_key" {
  description = "Public SSH key for the deploy user and the default user."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to reach port 22 during bootstrap. Restrict this to your current IP."
  type        = string
}

variable "deploy_user" {
  description = "Non-root user created by cloud-init."
  type        = string
  default     = "deploy"
}

variable "tailscale_auth_key" {
  description = "Optional single-use Tailscale auth key. Leave empty to join the tailnet manually."
  type        = string
  default     = ""
  sensitive   = true
}
