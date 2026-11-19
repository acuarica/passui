APP=PassUI.app
DMG=PassUI.dmg
BUILD=release

app:
	swift build --configuration $(BUILD)
	mkdir -p "$(APP)/Contents/MacOS"
	cp -f $$(swift build --configuration $(BUILD) --show-bin-path)/passui "$(APP)/Contents/MacOS"
	cp -f Info.plist "$(APP)/Contents"

dmg: app
	hdiutil create -verbose -volname "Pass UI" -srcfolder $(APP) -ov -format UDZO $(DMG)

clean:
	-rm -rv $(APP) $(DMG)

hooks:
	git config core.hooksPath .hooks
	@echo Git hooks installed in $$(git config core.hooksPath)
