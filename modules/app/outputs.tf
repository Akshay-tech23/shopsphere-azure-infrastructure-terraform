output "app_name" {
  description = "Application name passed into the example module."
  value       = terraform_data.app.output
}
