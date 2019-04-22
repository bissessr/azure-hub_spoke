variable "location" {
  description = "Location of the network"
  default     = "eastus"
}

variable "username" {
  description = "Username for Virtual Machines"
  default     = "testadmin"
}

variable "password" {
  description = "Password for Virtual Machines"
  default     = "Password1234!"
}

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_DS1_v2"
}
variable "application_port" {
    description = "The port that you want to expose to the external load balancer"
    default     = 80
}

variable "tags" {
 description = "A map of the tags to use for the resources that are deployed"
 type        = "map"

 default = {
   environment = "webapp1"
 }
}

