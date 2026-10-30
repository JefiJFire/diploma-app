# Идентификатор реестра: terraform output -raw registry_id (в terraform/bootstrap)
REGISTRY_ID ?=
# JSON-ключ сервисного аккаунта CI: terraform output -raw ci_sa_key_json
KEY         ?= $(HOME)/.config/yc/ci-sa-key.json
VERSION     ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)

LOCAL_IMAGE := diploma-app:$(VERSION)
IMAGE       := cr.yandex/$(REGISTRY_ID)/diploma-app:$(VERSION)

DOCKER_CFG  ?= $(HOME)/.docker-diploma

.PHONY: help build run login push

help:
	@echo "make build                         - собрать образ $(LOCAL_IMAGE)"
	@echo "make run                           - запустить локально: http://localhost:8090"
	@echo "make login REGISTRY_ID=<id>        - войти в Yandex Container Registry"
	@echo "make push  REGISTRY_ID=<id>        - собрать и отправить образ в реестр"
	@echo "Версия берётся из git (git describe), либо: make build VERSION=v1.0.0"

build:
	docker build --build-arg APP_VERSION=$(VERSION) -t $(LOCAL_IMAGE) .

run: build
	docker run --rm -p 8090:80 $(LOCAL_IMAGE)

login:
	@test -n "$(REGISTRY_ID)" || { echo "Укажите REGISTRY_ID=<id реестра>"; exit 1; }
	@test -f $(KEY) || { echo "Нет ключа $(KEY)"; exit 1; }
	@mkdir -p -m 700 $(DOCKER_CFG)
	cat $(KEY) | DOCKER_CONFIG=$(DOCKER_CFG) docker login --username json_key --password-stdin cr.yandex

push: build login
	docker tag $(LOCAL_IMAGE) $(IMAGE)
	DOCKER_CONFIG=$(DOCKER_CFG) docker push $(IMAGE)
	@echo "Образ: $(IMAGE)"
