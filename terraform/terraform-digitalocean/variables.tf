variable "do_token" {}


variable "domain_name" {
type=string
default="example.com"

}



variable "cluster_name" {
type=string
default="mycluster"


}


variable "region_name" {
type=string
default="lon1"               -> doctl kubernetes options regions

}

variable "cluster_version" {

type="string"
default="...."             -> doctl kubernetes options versions


}

variable "node_size" {

   type="string"
default="...."                             doctl kubernetes options sizes
}



variable "node_count"{

type=number
default=3  
}


variable "nginx_svc_name" {
type="string"
default="nginx-ingress-ingress-nginx-controller"

}