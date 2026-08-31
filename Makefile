.PHONY: build run app install clean

build:
	swift build

run: build
	./.build/debug/Notchi

app:
	./Scripts/bundle.sh release

install: app
	rm -rf /Applications/Notchi.app
	cp -R dist/Notchi.app /Applications/Notchi.app
	@echo "Installed to /Applications/Notchi.app"

clean:
	rm -rf .build dist
