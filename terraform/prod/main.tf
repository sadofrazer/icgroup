provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "/Users/sadofrazer/Données/DevOps/AWS/.aws/credentials"
}

terraform {
 backend "s3" {
   bucket                  = "terraform-backend-frazer"
   key                     = "frazer-prod.tfstate"
   region                  = "us-east-1"
   shared_credentials_file = "/Users/sadofrazer/Données/DevOps/AWS/.aws/credentials"
 }
}


#prodel du module de création du sg
module "sg" {
  source        = "../modules/sg"
  author = "prod"

}

# Appel du module de création de l'adresse ip pulique
module "eip" {
  source        = "../modules/eip"
}

# Appel du module de création de ec2
module "ec2" {
  source        = "../modules/ec2"
  author        = "prod"
  instance_type = "t2.micro"
  sg_name= "${module.sg.out_sg_name}"
  public_ip = "${module.eip.out_eip_ip}"
  user = "ubuntu"
  sudo_pass = "ubuntu"
}

#//////////////////////////////////////////////////
#Creation des associations nécessaires entre nos ressources

resource "aws_eip_association" "eip_assoc" {
  instance_id = module.ec2.out_instance_id
  allocation_id = module.eip.out_eip_id
}
