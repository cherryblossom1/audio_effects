all:

.PHONY: push
.PHONY: graph
push:
	git push https://cherryblossom1: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@github.com/cherryblossom1/phdwork.git
graph:
	git status
	git log --all --decorate --oneline --graph
#
