DOCKER_REGISTRY := docker.dragonfly.co.nz
IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
RUN ?= docker run $(DOCKER_ARGS) --runtime=nvidia --rm --ipc=host -v $$(pwd):/work -w /work -u $(UID):$(GID) $(IMAGE)
UID ?= $(shell id -u)
GID ?= $(shell id -g)
DOCKER_ARGS ?= 
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')

.PHONY: datasets train jupyter docker docker-push docker-pull enter enter-root

datasets: UrbanSound8K

datasets/UrbanSound8K.tar.gz:
	wget https://zenodo.org/record/1203745/files/UrbanSound8K.tar.gz -P datasets

UrbanSound8K: datasets/UrbanSound8K.tar.gz
	tar -xvf $<

train:
	$(RUN) python3 run.py train -c config.json --cfg crnn.cfg

test:
	$(RUN) python3 run.py UrbanSound8K/audio/fold10/100795-3-0-0.wav -r saved_cv/1114_031055/checkpoints/model_best.pth

tensorboard: TENSORBOARD_PORT=6006
tensorboard: DOCKER_ARGS=-p 6006:$(TENSORBOARD_PORT)
tensorboard: TENSORBOARD_LOG_DIR=saved_cv/1114_031055/logs
tensorboard:
	$(RUN) tensorboard --logdir $(TENSORBOARD_LOG_DIR) --port $(TENSORBOARD_PORT)

JUPYTER_PASSWORD ?= jupyter
JUPYTER_PORT ?= 8888
jupyter: UID=root
jupyter: GID=root
jupyter: DOCKER_ARGS=-u $(UID):$(GID) --rm -it -p $(JUPYTER_PORT):$(JUPYTER_PORT) -e NB_USER=$$USER -e NB_UID=$(UID) -e NB_GID=$(GID)
jupyter:
	$(RUN) bash -c 'jupyter lab \
		--allow-root \
		--port $(JUPYTER_PORT) \
		--ip 0.0.0.0 \
		--NotebookApp.iopub_msg_rate_limit=1000000 \
		--NotebookApp.password=$(shell $(RUN) \
			python3 -c \
			"from IPython.lib import passwd; print(passwd('$(JUPYTER_PASSWORD)'))"\
			)'

clean:
	rm -rf saved_cv/*

docker:
	docker build --tag $(IMAGE):$(GIT_TAG) .
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash
