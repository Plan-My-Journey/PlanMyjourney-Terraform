.PHONY: init fmt validate plan apply destroy output graph clean bootstrap

TFVARS = environments/prod.tfvars
PLAN_FILE = tfplan

bootstrap:
	@echo "Creating Terraform state backend in us-east-1..."
	aws s3api create-bucket \
		--bucket ai-travel-terraform-state-235270183260 \
		--region us-east-1 || true
	aws s3api put-bucket-versioning \
		--bucket ai-travel-terraform-state-235270183260 \
		--versioning-configuration Status=Enabled
	aws s3api put-bucket-encryption \
		--bucket ai-travel-terraform-state-235270183260 \
		--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
	aws s3api put-public-access-block \
		--bucket ai-travel-terraform-state-235270183260 \
		--public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
	aws dynamodb create-table \
		--table-name ai-travel-terraform-lock \
		--attribute-definitions AttributeName=LockID,AttributeType=S \
		--key-schema AttributeName=LockID,KeyType=HASH \
		--billing-mode PAY_PER_REQUEST \
		--region us-east-1 || true
	@echo "Backend created successfully."

init:
	terraform init -upgrade

fmt:
	terraform fmt -recursive

validate: fmt
	terraform validate

plan: validate
	terraform plan -var-file=$(TFVARS) -out=$(PLAN_FILE)

apply:
	terraform apply $(PLAN_FILE)

apply-auto: validate
	terraform apply -var-file=$(TFVARS) -auto-approve

destroy:
	terraform destroy -var-file=$(TFVARS)

output:
	terraform output

graph:
	terraform graph | dot -Tsvg > graph.svg
	@echo "Graph saved to graph.svg"

clean:
	rm -rf .terraform $(PLAN_FILE) .terraform.lock.hcl

show-costs:
	@echo "Run: infracost breakdown --path . --terraform-var-file=$(TFVARS)"

security-scan:
	@echo "Running checkov security scan..."
	checkov -d . --framework terraform

lint:
	tflint --recursive
