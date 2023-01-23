SHELL := /bin/bash -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
.DEFAULT_GOAL := help

# Terraformでのapply対象
# terraform/environments/<env>/配下のディレクトリ名と一致させる
# 依存関係を正しく解決できるように、依存関係の順序にしたがってハードコードしておく
STACKS := external base database app cicd monitoring

# Terraformのターゲット名
INIT_TARGETS := $(subst _,-,$(patsubst %,init-%,$(STACKS)))
PLAN_TARGETS := $(subst _,-,$(patsubst %,plan-%,$(STACKS)))
APPLY_TARGETS := $(subst _,-,$(patsubst %,apply-%,$(STACKS)))

# AWS CLI・Terraform実行時のリージョン
# 環境変数AWS_DEFAULT_REGIONが未指定の場合に、東京リージョンを使うように初期値をセット
REGION := $${AWS_DEFAULT_REGION:-ap-northeast-1}

# Terraform実行対象のベースディレクトリ
ENV_BASE_DIR := terraform/environments

# AWSアカウントID（bgl-big1234-dev）のような値から環境名の省略形（「dev・evl・stg・prd」のいずれかの値）を取り出し
# Terraform実行対象のディレクトリ名「terraform/environments/<full_env>」を生成する。
define generate_env_dir
	aws_account_id=$$(aws iam list-account-aliases --query AccountAliases[0] --output text --region $(REGION)) && \
	short_env=$$(echo $${aws_account_id} | rev | cut -c 1-3 | rev) && \
	if [ "$${short_env}" = "dev" ]; then echo $(ENV_BASE_DIR)/development; \
	elif [ "$${short_env}" = "evl" ]; then echo $(ENV_BASE_DIR)/evaluation; \
	elif [ "$${short_env}" = "stg" ]; then echo $(ENV_BASE_DIR)/staging; \
	elif [ "$${short_env}" = "prd" ]; then echo $(ENV_BASE_DIR)/production; \
	fi
endef

.PHONY: install
install: ## Terraformのインストール
	tfenv install

# terraform init
.PHONY: all-init
all-init: $(INIT_TARGETS) ## すべてのディレクトリでterraform init

.PHONY: $(INIT_TARGETS)
$(INIT_TARGETS): STACK = $(subst -,_,$(patsubst init-%,%,$@))
$(INIT_TARGETS):
	@env_dir=$$($(call generate_env_dir)) && \
	set -x && \
	terraform -chdir=$${env_dir}/$(STACK) init

# terraform plan
.PHONY: all-plan
all-plan: $(PLAN_TARGETS) ## すべてのディレクトリでterraform plan

.PHONY: $(PLAN_TARGETS)
$(PLAN_TARGETS): STACK = $(subst -,_,$(patsubst plan-%,%,$@))
$(PLAN_TARGETS):
	@env_dir=$$($(call generate_env_dir)) && \
	set -x && \
	terraform -chdir=$${env_dir}/$(STACK) init -input=false -no-color -reconfigure && \
	terraform -chdir=$${env_dir}/$(STACK) plan -input=false -no-color

# terraform apply
.PHONY: all-apply
all-apply: $(APPLY_TARGETS) ## すべてのディレクトリでterraform apply

.PHONY: $(APPLY_TARGETS)
$(APPLY_TARGETS): STACK = $(subst -,_,$(patsubst apply-%,%,$@))
$(APPLY_TARGETS):
	@env_dir=$$($(call generate_env_dir)) && \
	set -x && \
	terraform -chdir=$${env_dir}/$(STACK) init -input=false -no-color -reconfigure && \
	terraform -chdir=$${env_dir}/$(STACK) apply -input=false -auto-approve -no-color

# terraform destroy
.PHONY: destroy-database
destroy-database: ## database ディレクトリで terraform destroy
	@env_dir=$$($(call generate_env_dir)) && \
	set -x && \
	terraform -chdir=$${env_dir}/database init -input=false -no-color -reconfigure && \
	terraform -chdir=$${env_dir}/database destroy -input=false -auto-approve -no-color -target=module.aurora || true

.PHONY: destroy-app
destroy-app: ## app ディレクトリで terraform destroy
	@env_dir=$$($(call generate_env_dir)) && \
	set -x && \
	terraform -chdir=$${env_dir}/app init -input=false -no-color -reconfigure && \
	terraform -chdir=$${env_dir}/app destroy -input=false -auto-approve -target=module.online_ecs_service -target=module.batch_ecs_service

.PHONY: fmt
fmt: ## コードフォーマット
	terraform fmt -recursive

# https://postd.cc/auto-documented-makefile/
.PHONY: help
help: ## ヘルプを表示
	@echo $(PLAN_TARGETS) | sed 's/ /\n/g' | sort | awk '{s=$$1; sub(/-/,": ",s); printf "\033[36m%-30s\033[0m terraform %s\n", $$1, s}'
	@echo $(APPLY_TARGETS) | sed 's/ /\n/g' | sort | awk '{s=$$1; sub(/-/,": ",s); printf "\033[36m%-30s\033[0m terraform %s\n", $$1, s}'
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
