CHART_REPO := http://jenkins-x-chartmuseum:8080
NAME := velero-backup
OS := $(shell uname)

CHARTMUSEUM_CREDS_USR := $(shell cat /builder/home/basic-auth-user.json)
CHARTMUSEUM_CREDS_PSW := $(shell cat /builder/home/basic-auth-pass.json)

init:
	helm init --client-only

setup: init
	helm repo add jenkins-x http://chartmuseum.jenkins-x.io 	

build: clean setup
	helm dependency build velero-backup
	helm lint velero-backup

clean:
	rm -rf velero-backup/charts
	rm -rf velero-backup/${NAME}*.tgz
	rm -rf velero-backup/requirements.lock

release: clean build

	sed -i -e "s/version:.*/version: $(VERSION)/" velero-backup/Chart.yaml
	helm package velero-backup
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz
	jx step changelog  --verbose --version $(VERSION) --rev $(PULL_BASE_SHA)