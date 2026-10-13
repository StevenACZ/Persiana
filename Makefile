.PHONY: check format test build install-dev release appcast verify-release

check:
	swift format lint --strict -r Sources Tests Package.swift
	swift test
	scripts/build.sh
	python3 scripts/check-public-source.py
	for script in scripts/*.sh; do bash -n "$$script" || exit 1; done

format:
	swift format format -i -r Sources Tests Package.swift

test:
	swift test

build:
	scripts/build.sh

install-dev:
	scripts/install-dev.sh

release:
	scripts/package-release.sh

appcast:
	scripts/generate-appcast.sh

verify-release:
	scripts/verify-release.sh "$(ARTIFACT)"
