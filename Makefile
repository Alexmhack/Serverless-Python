.PHONY: runserver build push test run run-dev run-staging build-empty run-empty build-run build-run-empty

runserver:
	@uvicorn src.main:app --reload

build:
	@docker build -f Dockerfile -t serverless-python . --compress

run:
	@docker run -p 8000:8000 -e MODE=prod --rm --env-file .env --name serverless-python-container -it serverless-python

run-dev:
	@docker run -p 8000:8000 -e MODE=dev-env --rm --env-file .env --name serverless-python-container -it serverless-python

run-staging:
	@docker run -p 8000:8000 -e MODE=staging-env --rm --env-file .env --name serverless-python-container -it serverless-python

build-empty:
	@docker build -f Dockerfile.empty -t serverless-python-empty . --compress

run-empty:
	@docker run -p 8001:8000 --rm -it serverless-python-empty

build-run-empty:
	docker build -f Dockerfile.empty -t serverless-python-empty . --compress
	docker run -p 8001:8000 --rm --name serverless-python-empty-container -it serverless-python-empty

build-run:
	docker build -f Dockerfile -t serverless-python . --compress
	docker run -p 8000:8000 -e MODE=prod --rm --env-file .env --name serverless-python-container -it serverless-python

configure:
	gcloud auth configure-docker us-central1-docker.pkg.dev
	gcloud artifacts repository create serverless-python-repo --repository-format=docker

push:
	docker build -f Dockerfile -t serverless-python . --compress
	docker tag serverless-python us-central1-docker.pkg.dev/weather-friend-6ee52/serverless-python-repo/serverless-python:latest
	docker push us-central1-docker.pkg.dev/weather-friend-6ee52/serverless-python-repo/serverless-python --all-tags

deploy:
	gcloud run deploy serverless-python-run \
	--image=us-central1-docker.pkg.dev/weather-friend-6ee52/serverless-python-repo/serverless-python:latest \
	--region=us-central1 --allow-unauthenticated --project=weather-friend-6ee52

test:
	@pytest src/tests.py
