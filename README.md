# Serverless-Python
In this repository we are going to write a very basic python application and focus mainly on its deployment using GCP Cloud Run and the various things involved in the deployment process.

## Requirements

1. Installing the Google Cloud SDK for Ubuntu - Follow this simple [GCP Docs](https://cloud.google.com/sdk/docs/install#deb) for the installation process.
	Even after installation if you are run `gcloud` and the shell says command not found then,
	1. In case of Mac users, you can simply source your .zshrc file in the current terminal which is stored in your User's home directly for e.g. /home/User/.zshrc
	2. In case of Debian/Ubuntu users,

2. Docker
3. Python

## FastAPI

FastAPI gives us a very simple way to define the API endpoints, a very simple application would look like,

```
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def read_root():
	return {"Hello": "World"}

```

And then running this FastAPI server using `uvicorn`(`pip install uvicorn`) using the following command,

```
# uvicorn <folder_name>.<application_file_name>:<variable defining the FastAPI app>

uvicorn main.src:app

# Output
INFO:     Started server process [70086]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     127.0.0.1:37178 - "GET / HTTP/1.1" 200 OK
INFO:     127.0.0.1:37178 - "GET /favicon.ico HTTP/1.1" 404 Not Found
INFO:     127.0.0.1:42652 - "GET / HTTP/1.1" 200 OK
```

## Environment Variables Setup

We will be using the `python-decouple` module for setting up our environment variables, we can also use `python-dotenv`, but for this sake of tutorial we will go with `python-decouple`

```
pip install python-decouple
```

For separating our environment variables totally, we will be creating a *env.py* file and defining and getting our variables 
from there.

*src/env.py*
```
import pathlib

from decouple import Config, RepositoryEnv

BASE_DIR = pathlib.Path(__file__).parent.parent # this gives us the root dir of our project
ENV_PATH = BASE_DIR / ".env"

def get_config():
	if ENV_PATH.exists():
		return Config(RepositoryEnv(str(ENV_PATH)))

	from decouple import config
	return config

```

Since these environment variables will stay constant over the time run of our application, so we can cache them, for that we can make use of `lru_cache` from `functools`

```
from functools import lru_cache

@lru_cache()
def get_config():
	...


config = get_config()
```

Now in our other applications, we can simply import this config variable and use it as we use the config from `python-decouple`,


*src/main.py*
```
from .env import config
...
...

@app.get("/")
def read_root():
	return {"Hello": "World", "mode": config("MODE", default="test", cast=str)}
```

## Makefile

Makefile is a very easy to use CLI utility tool available on major Linux distributions, so in our case to actually run the 
server and other scripts we will make use of the `make` command which utilizes the *Makefile*,

*Makefile*
```
.PHONY: runserver

runserver:
	@uvicorn src.main:app --reload
```

The syntax of Makefile is very easy to understand and almost identical to .yaml/.yml files.

1. Here the `.PHONY: ` is used to skip the make command search for the `runserver` as a file or some other command and directly look into the *Makefile* to run it.

2. `@uvicorn ...` -> `@` will avoid printing the whole command on the shell and directly execute the command.


## Pytest

While deploying applications on Docker, Cloud Run etc, we must make sure to have some test cases and a test run in our CI/CD 
pipeline as well, this just ensure we don't deploy a bad build onto our production and avoids breaking the existing running 
app.

Since we are using FastAPI, we will be utilizing the test client from the module and write a simple test for our simple 
application for demo purposes.

Refer to *src/tests.py* for the test case code.
Run the pytest using `pytest src/tests.py`

As you might have noticed in the *Makefile*, we can add the above pytest run command in our *Makefile*


## Dockerfile

Containerzing our applications has many usecases, we can spin up and deploy this application onto many instances, VMs just 
using a single docker configuration stored in *Dockerfile*.

A good way about creating the *Dockerfile* that I have learned is to use the 3 steps practise,

1. What is system config -> More specifically the version of the Language or OS System that we are going to use for our project.
2. What is the code and the docs -> Code that will run once the new instance or a container is being initialized.
3. Running the application -> This is final step which lists down what actually our docker container would run.

A simple *Dockerfile* for our serverless python app usecase would look like,

```
## Which version of python
FROM python:3.8-slim

## What code and docs
# COPY local dir to the container dir
COPY ./src /app/
COPY ./requirements.txt /app/requirements.txt

# Mentioning what will be the working dir of this container
WORKDIR /app/

# Creating virtualenv
RUN python3 -m venv /opt/venv && \
	/opt/venv/bin/python -m pip install pip --upgrade && \
	/opt/venv/bin/python -m pip install -r /app/requirements.txt

## Run the app
CMD ["./entrypoint.sh"]
```

Some other useful and necessary commands to run are the Python3 setup commands of `apt-get` and `apt-get remove`, which you 
can take reference from the *Dockerfile* in this repo.

Now comes the build part. The whole point of building the *Dockerfile* was to be able to build our own image and then use 
that image for our containers. 

For demo purposes, we will be first creating a non-essential Docker build, we will name that build file as *Dockerfile.empty*
and add two more commands in the *Makefile* for the empty builds,

1. ```
build-empty:
	@docker build -f Dockerfile.empty -t serverless-python-empty .
```

2. ```
run-empty:
	@docker run -p 1234:8000 -it serverless-python-empty
```

The `docker run` commands takes a few arguments,

1. `-it` denotes to run the container in interactive mode.
2. `serverless-python-empty` is the tag name of the build image to use for this container.
3. `-p 1234:8000` is the port mapping, first part is the target port means the port to target outside the container and the second part of the mapping denotes the published port which is 8000 at which the FastAPI app will be listening on.


### Docker Environment Variables

While running the container using the `docker run` command we can specificy the environment variables to use,

For e.g.

1. Environment variables directly in the `run` command,
	```
	docker run -e MODE=dev -p 8001:8000 -it serverless-python-empty
	```

	We can also specify the name of the container explicitly to avoid using some random name,
	```
	docker run -e MODE=dev -p 8001:8000 --rm --name serverless-python-empty-container -it serverless-python-empty
	```

2. Environment variables using *.env* file,
	```
	docker run --env-file .env -p 8000:8000 -it serverless-python
	```
