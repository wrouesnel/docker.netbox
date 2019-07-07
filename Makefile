# where to download files too
BIN_DIR = .bin

SRC := $(shell find . \( -path './.git' -o -path './.docker.log' -o -path './.dockerid' -o -path './.debug.dockerid' -o -path './tests/venv' \) -prune -o -print)

DOCKER_HOST ?= unix:///var/run/docker.sock
DOCKER_BUILD_ARGS ?= --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(https_proxy)
EXTRA_BUILD_ARGS ?= 

RELEASE_NAME ?= 

CIDFILE ?= .cidfile

MAKECERTS := $(BIN_DIR)/makecerts

IMAGE_NAME=netbox

# Note: DEV_NETBOX_REMOTE_DEBUG_ENABLE does nothing unless you build with
# EXTRA_BUILD_ARGS="--build-arg PYTHON_REMOTE_DEBUGGING=yes"

DEV_SETTINGS := -e SSL_CLIENT_CACERT=disabled -e DEV_ALLOW_SELF_SIGNED=yes \
		-e DEV_ALLOW_EPHEMERAL_DATA=yes -e ADMIN_AUTH=disabled -e DEV_STANDALONE=yes \
		-e DEV_ALLOW_DEFAULT_TRUST=yes -e DEV_NO_ALERT_EMAILS=yes -e DEV_NO_SMARTHOST=yes \
		-e PSQL_PASSWORD=netbox -e ADMIN_AUTH=no -e DEV_NETBOX_DEBUG=yes \
		-e DEV_NETBOX_REMOTE_DEBUG_ENABLE=yes \
		-e DEV_NETBOX_REMOTE_DEBUG_HOST=$(shell ip addr show docker0 | grep -oP 'inet \S+ ' | cut -d ' ' -f2 | cut -d '/' -f1)

EXTRA_DEV_SETTINGS ?= 

.PHONY: run run-it enter-it testcerts test test-list tar release _buildargs

all: .dockerid

$(MAKECERTS):
	mkdir -p $(BIN_DIR)
	curl -s -o $@ -z $@ "https://github.com/wrouesnel/makecerts/releases/download/v0.4/makecerts.x86_64"
	chmod +x $@

.dockerid: $(SRC)
	docker build --iidfile="$@" $(DOCKER_BUILD_ARGS) $(EXTRA_BUILD_ARGS) $(IMAGE_NAME)

.debug.dockerid: $(SRC)
	docker build --iidfile="$@" $(DOCKER_BUILD_ARGS) $(EXTRA_BUILD_ARGS) --build-arg PYTHON_REMOTE_DEBUGGING=yes $(IMAGE_NAME)
	
tar: $(IMAGE_NAME).tar

$(IMAGE_NAME).tar: .dockerid
	docker save -o $(IMAGE_NAME).tar $(shell cat .dockerid)

enter-it: .dockerid
	rm -f $(CIDFILE)
	docker run $(DEV_SETTINGS) $(EXTRA_DEV_SETTINGS) \
		--tmpfs /run:suid,exec --tmpfs /tmp:suid,exec --tmpfs /data:suid,exec \
		--read-only --entrypoint=/bin/bash \
		-it --rm --cidfile=$(CIDFILE) $(EXTRA_RUN_ARGS) $(shell cat $<)

debug-it: .debug.dockerid
	rm -f $(CIDFILE)
	docker run $(DEV_SETTINGS) $(EXTRA_DEV_SETTINGS) \
		--tmpfs /run:suid,exec --tmpfs /tmp:suid,exec --tmpfs /data:suid,exec \
		-v $(shell readlink -f netbox/tree-postinstall/opt/netbox):/opt/netbox \
		--read-only \
		-it --rm --cidfile=$(CIDFILE) $(EXTRA_RUN_ARGS) $(shell cat $<)
				
run-it: .dockerid
	rm -f $(CIDFILE)
	docker run $(DEV_SETTINGS) $(EXTRA_DEV_SETTINGS) \
		--tmpfs /run:suid,exec --tmpfs /tmp:suid,exec --tmpfs /data:suid,exec \
		--read-only \
		-it --rm --cidfile=$(CIDFILE) $(EXTRA_RUN_ARGS) $(shell cat $<)

run: .dockerid
	rm -f $(CIDFILE)
	docker run --rm --cidfile=$(CIDFILE) $(shell cat $<)

# Exec's into the most recently run container.
exec-into:
	docker exec -it $(shell cat $(CIDFILE)) /bin/bash

get-ip:
	@docker inspect -f '{{ .NetworkSettings.IPAddress }}' $(shell cat $(CIDFILE))

clean:
	rm -f $(CIDFILE) .dockerid

release:
	@if [ ! -z "$(RELEASE_NAME)" ] ; then \
		docker tag $(shell cat .dockerid) $(RELEASE_NAME)/$(IMAGE_NAME):latest ; \
		docker push $(RELEASE_NAME)/$(IMAGE_NAME):latest ; \
	else \
		echo "ERROR: Can't release - no release-name specified" ; \
		exit 1 ; \
	fi
