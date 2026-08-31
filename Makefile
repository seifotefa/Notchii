.PHONY: build run app install release signing-check clean

build:
	swift build

run: build
	./.build/debug/Notchii

app:
	./Scripts/bundle.sh release

install: app
	rm -rf /Applications/Notchii.app
	cp -R dist/Notchii.app /Applications/Notchii.app
	@echo "Installed to /Applications/Notchii.app"

signing-check:
	./Scripts/signing-check.sh

release:
	./Scripts/release.sh $(VERSION)

clean:
	rm -rf .build dist
