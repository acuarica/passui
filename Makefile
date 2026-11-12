APP=PassUI.app
BUILD=release

app:
	swift build --configuration $(BUILD)
	mkdir -p "$(APP)/Contents/MacOS"
	cp -f $$(swift build --configuration $(BUILD) --show-bin-path)/passui "$(APP)/Contents/MacOS"
	cp -f Info.plist "$(APP)/Contents"

clean:
	-rm -rv $(APP)

hooks:
	git config core.hooksPath .githooks
	@echo Git hooks installed in `git config core.hooksPath`

show-hooks:
	git config core.hooksPath
