.PHONY: install lint test format

install:
	pip install -r requirements-dev.txt

lint:
	ruff src
	mypy src

format:
	black src

test:
	pytest
