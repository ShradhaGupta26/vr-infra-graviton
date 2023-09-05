data "template_file" "kms" {
  template = "${file("${path.module}/kms_policy.json.tpl")}"
  vars = {
    Account_ID = "${local.workspace.aws.account_id}"
    Role_Name = "${local.workspace.kms_policy.role_name}"
  }
}