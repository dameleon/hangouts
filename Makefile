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
	$(RUN) claude --dangerously-skip-permissions $(ARGS)

codex:
	$(RUN) codex --full-auto $(ARGS)

gemini:
	$(RUN) gemini --yolo $(ARGS)

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
