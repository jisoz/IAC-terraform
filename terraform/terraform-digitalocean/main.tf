terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version= "2.21.0"
    }
  }
}

provider "digitalocean" {
 token= var.do_token
}



resource "digitalocean_ssh_key" "web" {

name = "web app ssh key" 
public_key = file("${path.module}/files/id_rsa.pub")

}

resource "digitalocean_droplet" "web" {
 count = 2 
 image="ubuntu-18-10-x64"
 name="web-${count.index}" 
 region="lon1"
 size="s-1vcpu-1gb"
 monitoring=true
 private_networking=true
 ssh_keys=[
  digitalocean_ssh_key.web.id                        
 ]

 user_data=file("${path.module}/files/user_data.sh)
}



resource  "digitalocean_loadbalancer" "web" {
name ="web-lb"
region = "lon1"

forwarding_rule {
  entry_port = 443
  entry_protocol = "https"
  target_port = 8080
  target_protocol="http"
  
  certificate_id=digitalocean_certificate.web.id
}

forwarding_rule {
  entry_port = 80
  entry_protocol = "http"
  target_port = 8080
  target_protocol="http"
  
}

healthcheck {
port =8080
protocol = "http"
path = "/"
}
redirect_http_to_https = true

droplet_ids=digitalocean_droplet.web.*.id

}




resource "digitalocean_domain" "domain" {
name = "var.domain_name"                      -> point the domain to custom servers of digital ocean (ns.digitalocean.com)

}

resource "digitalocean_record" "main"{
domain= digitalocean_domain.domain.name
type= "A"
name="@"
value=digitalocean_loadbalancer.web.ip

}


resource "digitalocean_certificate" "web" {
name="web-cert"
type=" lets_encrypt"
domains = ["example.com"]


}



resource "digitalocean_firewall" "web" {
  name = "only-22-80-and-443"

  droplet_ids = [digitalocean_droplet.web.*.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["192.168.1.0/24", "2002:1:2::/48"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
    
    source_load_balencer_uids = [digitalocean_loadbalancer.web.id]
  }


  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}















############ kubernetes app ###########

terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version= "2.21.0"
    }

    kubernetes ={
     source="hashicorp/kubernetes"
     version="2.11.0"
    }

    helm = {
       source = "hashicorp/helm"
       version= "2.6.0"
    }
  }
}

provider "digitalocean" {
 token= var.do_token
}



provider "helm" {
  kubernetes {
    host                   = digitalocean_kubernetes_cluster.mycluster.endpoint
    cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.mycluster.kube_config.0.cluster_ca_certificate
    )
   
   exec  {
   api_version = "client.authentication.k8s.io/v1beta1"
   command = "doctl"
   args = ["kubernetes" , "cluster" , "kubeconfig" , "exec-credential" , "--version=v1beta1" , digitalocean_kubernetes_cluster.mycluster.id] 
   }
  }
}



provider "kubernetes" {
  host = digitalocean_kubernetes_cluster.mycluster.endpoint
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.mycluster.kube_config.0.cluster_ca_certificate
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "doctl"
    args = ["kubernetes", "cluster", "kubeconfig", "exec-credential",
    "--version=v1beta1", digitalocean_kubernetes_cluster.mycluster.id]
  }
}






resource "digitalocean_domain" "domain" {
name = "var.domain_name"                      -> point the domain to custom servers of digital ocean (ns.digitalocean.com)

}

resource  "digitalocean_record" "main_record" {
 depends_on = [ data.kubernetes_service_v1.ingress_svc]
 domain= digitalocean_domain.domain.id
 type = "A"
 name = "@"
 value = data.kubernetes_service_v1.ingress_svc.status.0.load_balencer.0.ingress.0.ip

}
resource "digitalocean_kubernetes_cluster" "mycluster" {
  name   = var.cluster_name
  region = var.region_name
 
  version = var.cluster_version 


  node_pool {
    name       = "worker-pool"
    size       = "var.node_size"
    node_count = "var.node_count"

   
  }

}


resource "helm_release" "nginx_ingress" {

depends_on =[digitalocean_kubernetes_cluster.mycluster]
name = "nginx-ingress"
repository="https://kubernetes.github.io/ingress-nginx"
chart="ingress-nginx"



set {
name = "controller.publishService.enabled
value= "true"
}


}


data "kubernetes_service_v1" "ingress_svc" {
 depends_on= [helm_release.nginx_ingress]
 metadata {                                                      

   name=var.nginx_svc_name
 }

}




  output "my-kubeconfig" {
   value = "digitalocean_kubernetes_cluster.mycluster.kube_config.0.raw_config   -> This will create a Kubernetes cluster on DigitalOcean and output the kubeconfig, allowing you to connect and manage your cluster.
   sensitive=true
  }




  
resource "helm_release" "postgres" {

depends_on =[digitalocean_kubernetes_cluster.mycluster]
name = "postgres"
repository="https://charts.bitnami.com/bitnami"
chart="postgresql-ha"

values= [ "${file("./k8s/psql-values.yml")}" ] 