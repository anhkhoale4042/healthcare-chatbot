install:
	pip install -r requirements.txt
	pip install -r requirements-dev.txt

lint:
	pre-commit run --all-files

test:
	pytest tests

run:
	python -m src
