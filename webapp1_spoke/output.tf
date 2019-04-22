output "public_ip_id" {
  description = "Workload Public IP"
  value = "${azurerm_public_ip.webapp1-workload.id}"
}
