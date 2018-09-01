VERSION ?= dirty

default: build

build:
	VERSION=${VERSION} docker build -t image-builder-rpi64 .

sd-image: build
	VERSION=${VERSION} docker run --rm --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e CIRCLE_TAG -e VERSION -e GITHUB_OAUTH_TOKEN image-builder-rpi64

shell: build
	VERSION=${VERSION} docker run -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e CIRCLE_TAG -e VERSION -e GITHUB_OAUTH_TOKEN image-builder-rpi64 bash

test:
	VERSION=${VERSION} docker run --rm -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e CIRCLE_TAG -e VERSION image-builder-rpi64 bash -c "unzip /workspace/hypriotos-rpi64-${VERSION}.img.zip && rspec --format documentation --color /workspace/builder/test/*_spec.rb"

shellcheck: build
	VERSION=${VERSION} docker run --rm -ti -v $(shell pwd):/workspace image-builder-rpi64 bash -c 'shellcheck /workspace/builder/*.sh /workspace/builder/files/etc/firstboot.d/*'

test-integration: test-integration-image test-integration-docker

test-integration-image:
	docker run --rm -ti -v $(shell pwd)/builder/test-integration:/serverspec:ro -e BOARD uzyexe/serverspec:2.24.3 bash -c "rspec --format documentation --color spec/hypriotos-image"

test-integration-docker:
	docker run --rm -ti -v $(shell pwd)/builder/test-integration:/serverspec:ro -e BOARD uzyexe/serverspec:2.24.3 bash -c "rspec --format documentation --color spec/hypriotos-docker"

tag:
	git tag ${TAG}
	git push origin ${TAG}
