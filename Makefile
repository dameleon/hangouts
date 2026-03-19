IMAGE_NAME := hangouts
WORKSPACE  ?= $(PWD)
DC         := docker compose
RUN        := $(DC) run --rm -e HOST_WORKSPACE_PATH=$(WORKSPACE) hangouts

.PHONY: build shell clean claude codex gemini gh difit copilot run prepare

build:
	$(DC) build

shell:
	$(RUN) bash

prepare:
	bash scripts/prepare-claude.sh

claude: prepare
	$(RUN) claude --dangerously-skip-permissions $(ARGS)

codex:
	$(RUN) codex --yolo $(ARGS)

gemini:
	$(RUN) gemini --yolo $(ARGS)

gh:
	$(RUN) gh $(ARGS)

copilot:
	$(DC) run --rm -e GITHUB_TOKEN= hangouts copilot --yolo $(ARGS)

difit:
	$(RUN) difit $(ARGS)

run:
	$(RUN) $(CMD)

clean:
	$(DC) down --rmi local
