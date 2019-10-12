terraform {
  backend "s3" {
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OUR KUBERNETES CONNECTIONS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

provider "kubernetes" {
  config_path    = abspath("../../kubernetes-cluster/.kube")
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OUR HELM PROVIDER 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
provider "helm" {
  version        = "~> 0.9"
  install_tiller = false
  client_certificate     = file("../../kubernetes-tiller/.secret/helm_client_tls_public_cert_pem.pem")
  client_key             = file("../../kubernetes-tiller/.secret/helm_client_tls_private_key_pem.pem")
  ca_certificate = file("../../kubernetes-tiller/.secret/helm_client_tls_ca_cert_pem.pem")
  namespace = "tiller"

  kubernetes {
    config_path = abspath("../../kubernetes-cluster/.kube")
  }
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE THE NAMESPACE WITH RBAC ROLES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"
  }
}

data "helm_repository" "istio" {
    name = "istio.io"
    url  = "https://storage.googleapis.com/istio-release/releases/1.3.2/charts/"
}

resource "helm_release" "istio-1-3-init" {
    name       = "istio-init"
    repository = "${data.helm_repository.istio.metadata.0.name}"
    chart      = "istio-init"
    namespace  = "${kubernetes_namespace.istio-system.metadata.0.name}"
}

resource "helm_release" "istio-1-3" {
    name       = "istio"
    repository = "${data.helm_repository.istio.metadata.0.name}"
    chart      = "istio"
    namespace  = "${kubernetes_namespace.istio-system.metadata.0.name}"

    values = [
      templatefile("values.yaml",{ })
    ]  

}