IMAGE_NAME := hangouts
WORKSPACE  ?= $(PWD)
DC         := docker compose
RUN        := $(DC) run --rm hangouts

.PHONY: build shell clean claude codex gemini gh difit copilot run

build:
	$(DC) build

shell:
	$(RUN) bash

claude:
	$(RUN) claude

codex:
	$(RUN) codex

gemini:
	$(RUN) gemini

gh:
	$(RUN) gh $(ARGS)

copilot:
	$(RUN) copilot $(ARGS)

difit:
	$(RUN) difit $(ARGS)

run:
	$(RUN) $(CMD)

clean:
	$(DC) down --rmi local
