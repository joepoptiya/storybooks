PROJECT_ID=devops-joepop-storybooks
ENV=staging
ZONE=us-central1-a

run-local:
	docker-compose up

###

create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraform

###

define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID)) 
endef

###

terraform-create-workspace:
	cd terraform && \
	  terraform workspace new $(ENV)

terraform-init:
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform init

TF_ACTION?=plan
terraform-action:
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform $(TF_ACTION) \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars" \
		-var="mongodbatlas_private_key="$(call get-secret,atlas_private_key) \
		-var="atlas_user_password="$(call get-secret,atlas_user_password_$(ENV)) \
		-var="cloudflare_api_key="$(call get-secret,cloudflare_api_key)

###
terraform-show-secrets:
	echo $(_atlas_user_password), $(_cloudflare_api_key), $(_cloudflare_api_token), $(_mongodbatlas_private_key)

###

SSH_STRING=joe.poptiya@devops-joepop-storybooks-$(ENV)
VERSION?=latest
LOCAL_TAG=jp-storybooks-app:$(VERSION)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)

ssh: 
	gcloud compute ssh \
		--zone $(ZONE) $(PROJECT_ID)-vm-$(ENV) \
		--tunnel-through-iap \
		--project $(PROJECT_ID) 

ssh-cmd: 
	gcloud compute ssh \
		--zone $(ZONE) $(PROJECT_ID)-vm-$(ENV) \
		--tunnel-through-iap \
		--project $(PROJECT_ID) \
		--command="$(CMD)"

build:
	docker build -t $(LOCAL_TAG) .

# Requires:  gcloud auth configure-docker 
push:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)
