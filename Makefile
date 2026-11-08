hooks:
	git config core.hooksPath .githooks
	@echo Git hooks installed in `git config core.hooksPath`

show-hooks:
	git config core.hooksPath
