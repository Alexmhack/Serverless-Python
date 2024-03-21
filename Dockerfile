## Which python version
FROM python:3.8-slim

RUN apt-get update && \
	apt-get install -y \
	build-essential \
	python3-dev \
	python3-setuptools \
	gcc \
	make

## Code
COPY . /app/
# COPY ./requirements.txt /app/requirements.txt

WORKDIR /app/

RUN python3 -m venv /opt/venv && \
	/opt/venv/bin/python -m pip install --upgrade pip && \
	/opt/venv/bin/python -m pip install -r /app/requirements.txt

RUN apt-get remove -y --purge gcc build-essential && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists*

RUN chmod +x ./src/entrypoint.sh

CMD ["./src/entrypoint.sh"]
