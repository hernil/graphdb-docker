VERSION=10.0.2
REPONAME=CIM

all: build-image import move-imported start-silent

build-image:
	docker build --pull --build-arg version=${VERSION} -t ontotext/graphdb:${VERSION} .

import: build-image
	sed -i "s/REPONAME_HERE/${REPONAME}/" preload/graphdb-repo.ttl
	cd preload && docker-compose build && docker-compose up
	sed -i "s/${REPONAME}/REPONAME_HERE/" preload/graphdb-repo.ttl

move-imported:
	mv preload/import/* preload/imported/. || return 0

start: build-image
	docker-compose up

start-silent: build-image
	docker-compose up -d

stop:
	docker-compose stop

reset: stop
	sudo rm -rf graphdb-data

push:
	docker push ontotext/graphdb:${VERSION}
