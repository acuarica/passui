
APP=PassUI.app

app:
	swift build --configuration release
	mkdir -p "$(APP)/Contents/MacOS"
	cp -f $$(swift build --configuration release --show-bin-path)/passui "$(APP)/Contents/MacOS"
	cp -f Info.plist "$(APP)/Contents"

clean:
	-rm -rv $(APP)

hooks:
	git config core.hooksPath .githooks
	@echo Git hooks installed in `git config core.hooksPath`

show-hooks:
	git config core.hooksPath
