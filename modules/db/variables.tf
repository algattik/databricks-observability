variable "resource_group_name" {
}
variable "owner_custom" {
  description = "Short name of owner"
}

variable "purpose_custom" {
  description = "Custom purpose"
}
variable "location" {
  description = "Location in which resource needs to be spinned up"
}

variable "key_vault_id" {
  description = "Key vault ID to store generate and store secrets"
}
