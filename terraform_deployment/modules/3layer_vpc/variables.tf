variable "region" {
    description = "deployment region"
    type        = string
    default     = "us-west-1"
}
variable "vpc_attrs" {
  description = "VPC expected attributes"
  
  type = object({
      name = string
      cidr = string
  })
  default = {
      name = "main-vpc"
      cidr = "172.23.0.0/16"
  }
}
variable "pub_sn_attrs" {
  description = "Public Subnets expected attributes"
  
  type = object({
      name      = string
      cidr_list = list(string)
  })
  default = {
      name      = "public-sn"
      cidr_list = ["172.23.0.0/24", "172.23.1.0/24"]
  }
}
variable "priv_sn_attrs" {
  description = "Private Subnets expected attributes"
  
  type = object({
      name      = string
      cidr_list = list(string)
  })
  default = {
      name      = "private-sn"
      cidr_list = ["172.23.32.0/24", "172.23.33.0/24"]
  }
}
variable "data_sn_attrs" {
  description = "Data Subnets expected attributes"
  
  type = object({
      name      = string
      cidr_list = list(string)
  })
  default = {
      name      = "data-sn"
      cidr_list = ["172.23.64.0/24", "172.23.65.0/24"]
  }
}
variable "azs" {
    description = "Letter values for AZs"

    type    = list(string)
    default = [ 
        "a", 
        "b", 
        "c" 
    ]
}
variable "common_tags" {
    type = map(string)
    description = "Common Tags to be used across all resources - Project Metadata"
    default = {
        Project = "Placeholder"
    }
}