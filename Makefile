include local.sh

# SERVER_ID : local.sh で定義
# GIT_USER_EMAIL : local.sh で定義
# GIT_USER_NAME : local.sh で定義
# GIT_CUSTOM_CONFIG : local.sh で定義
# APP_IPADDR : local.sh で定義

#
# 問題によって変わる変数
#
USER := isucon
APP_NAME := isuports
APP_DIR := /home/isucon/webapp/php
SERVICE_NAME := $(APP_NAME).service

PROJECT_ROOT := /home/isucon/webapp

DB_PATH := /etc/mysql
NGINX_PATH := /etc/nginx
SYSTEMD_PATH := /etc/systemd/system

NGINX_LOG := /var/log/nginx/access.log
DB_SLOW_LOG := /tmp/slow-query.log

$(eval ARCH := $(shell uname -m))

.PHONY: setup
setup: install-tools git-setup migrate-service

.PHONY: get-conf
get-conf: check-server-id get-db-conf get-nginx-conf get-service-file get-envsh get-php-conf

.PHONY: deploy-conf
deploy-conf: check-server-id deploy-db-conf deploy-nginx-conf deploy-service-file deploy-envsh deploy-php-conf

.PHONY: bench
bench: check-server-id mv-logs build deploy-conf restart watch-service-log

.PHONY: bench-dev
bench-dev: bench
	sleep 1
	/bin/sh bench.sh

.PHONY: alp
alp:
	sudo alp json --file=$(NGINX_LOG) --config=./tool-config/alp/config.yml

.PHONY: slow-query
slow-query:
ifeq ("$(wildcard $(DB_SLOW_LOG))", "")
	$(error $(DB_SLOW_LOG) not found)
endif
	sudo pt-query-digest $(DB_SLOW_LOG)

.PHONY: alp-diff
.ONESHELL:
alp-diff:
	@read -p "compare filepath: " filepath; \
	(
		echo $$filepath
		sudo cat $(NGINX_LOG) | alp json --config=./tool-config/alp/config.yml --dump current.yml
		sudo cat $$filepath | alp json --config=./tool-config/alp/config.yml --dump $(basename $(dirname $(dirname $$filepath))).yml
		alp diff $(basename $(dirname $(dirname $$filepath))).yml current.yml -o count,method,uri,sum,min,avg,max,p99,p95 --sort=count -r --show-footers

		rm current.yml $(basename $(dirname $(dirname $$filepath))).yml
	)


#
# サブコマンド
#

.PHONY: install-tools
install-tools:
	sudo apt-get -y update
	sudo apt-get -y install percona-toolkit htop dstat git unzip tree

	# alp
ifeq ($(ARCH), x86_64)
	curl -L https://github.com/tkuchiki/alp/releases/download/v1.0.10/alp_linux_amd64.zip -o alp.zip
else
	curl -L https://github.com/tkuchiki/alp/releases/download/v1.0.10/alp_linux_arm64.zip -o alp.zip
endif
	unzip alp.zip
	sudo install alp /usr/local/bin/alp
	rm alp alp.zip

.PHONY: git-setup
git-setup:
	git config --global user.email "$(GIT_USER_EMAIL)"
	git config --global user.name "$(GIT_USER_NAME)"
	$(GIT_CUSTOM_CONFIG)

.PHONY: migrate-service
migrate-service:
# マニュアルに書かれていると思うのでそれに差し替える
ifneq ("$(wildcard /etc/nginx/sites-enabled/$(APP_NAME).conf)", "")
	sudo unlink /etc/nginx/sites-enabled/$(APP_NAME).conf
endif
ifeq ("$(wildcard /etc/nginx/sites-enabled/$(APP_NAME)-php.conf)", "")
	sudo ln -s /etc/nginx/sites-available/$(APP_NAME)-php.conf /etc/nginx/sites-enabled/$(APP_NAME)-php.conf
endif
	sudo systemctl restart nginx.service
	sudo systemctl restart $(APP_NAME).service


.PHONY: check-server-id
check-server-id:
ifdef SERVER_ID
	@echo "SERVER_ID=$(SERVER_ID)"
else
	$(error SERVER_ID in unset)
endif

# get-conf: check-server-id get-db-conf get-nginx-conf get-service-file get-envsh get-php-conf
.PHONY: get-db-conf
get-db-conf:
	$(eval dest := "$(PROJECT_ROOT)/$(SERVER_ID)/etc/mysql")
	mkdir -p $(dest)
	sudo cp -R $(DB_PATH)/* $(dest)
	sudo chown $(USER) -R $(dest)

.PHONY: get-nginx-conf
get-nginx-conf:
	$(eval dest := "$(PROJECT_ROOT)/$(SERVER_ID)/etc/nginx")
	mkdir -p $(dest)
	sudo cp -R $(NGINX_PATH)/* $(dest)
	sudo chown $(USER) -R $(dest)

.PHONY: get-service-file
get-service-file:
	$(eval dest := "$(PROJECT_ROOT)/$(SERVER_ID)/etc/systemd/system")
	mkdir -p $(dest)
	sudo cp -R $(SYSTEMD_PATH)/$(SERVICE_NAME) $(dest)
	sudo chown $(USER) -R $(dest)

.PHONY: get-envsh
get-envsh:
	:

.PHONY: get-php-conf
get-php-conf:
	:

# deploy-conf: check-server-id deploy-db-conf deploy-nginx-conf deploy-service-file deploy-envsh deploy-php-conf
.PHONY: deploy-db-conf
deploy-db-conf:
	sudo cp -R $(PROJECT_ROOT)/$(SERVER_ID)/etc/mysql/* $(DB_PATH)

.PHONY: deploy-nginx-conf
deploy-nginx-conf:
	sudo cp -R $(PROJECT_ROOT)/$(SERVER_ID)/etc/nginx/* $(NGINX_PATH)

.PHONY: deploy-service-file
deploy-service-file:
	sudo cp $(PROJECT_ROOT)/$(SERVER_ID)/etc/systemd/system/$(SERVICE_NAME) $(SYSTEMD_PATH)/$(SERVICE_NAME)

.PHONY: deploy-envsh
deploy-envsh:
	:

.PHONY: deploy-php-conf
deploy-php-conf:
	:


# bench: check-server-id mv-logs build deploy-conf restart watch-service-log
.PHONY: mv-logs
mv-logs:
	$(eval when := $(shell date "+%Y%m%d-%H%M%S"))
	mkdir -p $(PROJECT_ROOT)/logs/$(when)/nginx $(PROJECT_ROOT)/logs/$(when)/mysql
ifneq ("$(wildcard $(NGINX_LOG))", "")
	sudo mv -f $(NGINX_LOG) $(PROJECT_ROOT)/logs/$(when)/nginx
endif
ifneq ("$(wildcard $(DB_SLOW_LOG))", "")
	sudo mv -f $(DB_SLOW_LOG) $(PROJECT_ROOT)/logs/$(when)/mysql
endif

.PHONY: build
build:
	:

.PHONY: deploy-conf
deploy-conf:
	:

.PHONY: restart
restart:
	sudo systemctl daemon-reload
	sudo systemctl restart $(SERVICE_NAME)
	sudo systemctl restart mysql
	sudo systemctl restart nginx

.PHONY: watch-service-log
watch-service-log:
	:

.PHONY: journal
journal:
	sudo journalctl -u $(SERVICE_NAME) -n 100 -f

.PHONY: clean
clean:
	rm -rf $(PROJECT_ROOT)/logs/*
	mkdir -p $(PROJECT_ROOT)/logs
	touch $(PROJECT_ROOT)/logs/.keep

.PHONY: test
test:
	# 何か実験したい時にここに書く
	:
