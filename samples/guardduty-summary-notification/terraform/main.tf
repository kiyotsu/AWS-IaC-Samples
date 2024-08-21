module "guardduty_summary_notification" {
  source             = "./modules/guardduty-summary-notification"
  env                = "prod"
  severity_threshold = 4.0
}
