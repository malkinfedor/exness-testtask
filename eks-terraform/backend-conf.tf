terraform {
backend "s3" {
   region         = "eu-west-1"
   bucket         = "terraform-eks-cluster"
   key            = "terraform.tfstate"
   encrypt        = "true"
   #dynamodb_table = "terraform-state-lock"
   }
}
