CONFIG_DIR = $(HOME)/.config/audiotier

.PHONY: build app dmg install uninstall run config clean

build:
	swift build -c release

app: build
	bash scripts/build-app.sh

dmg: app
	bash scripts/build-dmg.sh

install: app config
	cp -R "build/AudioTier.app" /Applications/
	@echo "Installed to /Applications/AudioTier.app"

config:
	mkdir -p $(CONFIG_DIR)
	@if [ ! -f $(CONFIG_DIR)/config.json ]; then \
		cp config.default.json $(CONFIG_DIR)/config.json; \
		echo "Created config at $(CONFIG_DIR)/config.json"; \
	else \
		echo "Config already exists at $(CONFIG_DIR)/config.json"; \
	fi

uninstall:
	-osascript -e 'quit app "AudioTier"' 2>/dev/null
	-rm -rf "/Applications/AudioTier.app"
	@echo "Uninstalled"

run:
	swift run

clean:
	rm -rf build .build
