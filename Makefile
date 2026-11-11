
APP=PassUI.app

app:
	mkdir -p "$(APP)/Contents/MacOS"
	cp -f $$(swift build --configuration debug --show-bin-path)/sinit "$(APP)/Contents/MacOS"
	cp -f Info.plist "$(APP)/Contents"

clean:
	rm -r $(APP)

hooks:
	git config core.hooksPath .githooks
	@echo Git hooks installed in `git config core.hooksPath`

show-hooks:
	git config core.hooksPath
