
terraform {

  before_hook "before_plan" {
    commands = ["plan"]
    execute = ["/bin/bash","-c","${get_terragrunt_dir()}/../kubernetes-cluster/export_kubeconfig.sh","${get_terragrunt_dir()}"]
    run_on_error = false
  }
}

include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["${get_terragrunt_dir()}/../kubernetes-cluster"]
}
