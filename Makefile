PROJECT_ID=devops-joepop-storybooks

run-local:
	docker-compose up

###

create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraform

###

ENV=staging

terraform-create-workspace:
	cd terraform && \
	  terraform workspace new $(ENV)

terraform-init:
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform init

terraform-plan:
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform plan \
	  -var-file="./environments/common.tfvars" \
	  -var-file="./environments/$(ENV)/config.tfvars"