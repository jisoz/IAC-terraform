provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region     = var.AWS_REGION
}


// we can now make method 1 :  teraform plan -var AWS_ACCESS_KEY="" -var  AWS_SECRET_KEY=""
//     method 2 :  create terraform.tfvariables  -> AWS_ACCESS_KEY="" -> put it in gitignore  and with terraform plan will work 
                                                    AWS_SECRET_KEY=""
               