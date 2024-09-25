# DigitalOcean Personal Access Token, which is used to authenticate Terraform with the DigitalOcean cloud provider

#in terminal 
export DO_TOKEN="your_digitalocean_api_token"
touch terraform.tfvars
echo "do_token="\"$DO_TOKEN\" > terraform.tfvars
