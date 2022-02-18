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
CONTAINER_NAME=jp-storybooks-app
GOOGLE_CLIENT_ID=864314013955-j6395re7dpcotqjgbadk0pj8ufl90edj.apps.googleusercontent.com

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

deploy:
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'
	@echo "removing old container..."
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	@echo "starting new container..."
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
			-e PORT=3000 \
			-e \"MONGO_URI=mongodb+srv://devops-joepop-storybooks-$(ENV):$(call get-secret,atlas_user_password_$(ENV))@devops-joepop-storybook-$(ENV).auafs.mongodb.net/devops-joepop-storybooks?retryWrites=true&w=majority\" \
			-e GOOGLE_CLIENT_ID=$(GOOGLE_CLIENT_ID) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,google_oauth_client_secret) \
			$(REMOTE_TAG) \
			'

#			-e \"MONGO_URI=mongodb+srv://storybooks-user-$(ENV):$(call get-secret,atlas_user_password_$(ENV))@storybooks-$(ENV).kkwmy.mongodb.net/$(DB_NAME)?retryWrites=true&w=majority\" \