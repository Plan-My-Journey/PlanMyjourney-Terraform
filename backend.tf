terraform {
  backend "s3" {
    bucket         = "ai-travel-terraform-state-235270183260"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "ai-travel-terraform-lock"
    # Bootstrap commands (run ONCE before terraform init):
    # aws s3api create-bucket --bucket ai-travel-terraform-state-235270183260 --region us-east-1
    # aws s3api put-bucket-versioning --bucket ai-travel-terraform-state-235270183260 --versioning-configuration Status=Enabled
    # aws s3api put-bucket-encryption --bucket ai-travel-terraform-state-235270183260 --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}"
    # aws dynamodb create-table --table-name ai-travel-terraform-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
  }
}
