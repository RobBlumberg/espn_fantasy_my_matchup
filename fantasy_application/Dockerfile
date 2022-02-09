FROM python:3.7.6

WORKDIR /home/app

# Install ssh tool to install private dependencies
RUN apt-get update && \
    apt-get install -y \
        git \
        openssh-server

# Download public key for github.com
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# Install poetry
RUN pip install poetry

# Copy in the poetry files
COPY pyproject.toml poetry.lock ./

# Install dependencies. First dump poetry.lock into requirements.txt, then install with ssh key
RUN poetry config virtualenvs.create false
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt
RUN --mount=type=ssh,id=github_ssh_key pip install -r requirements.txt --no-cache && \
    rm -rf pyproject.toml poetry.lock requirements.txt

# copy app files
COPY fantasy_application/ /home/app/fantasy_application/

# set environment variables
ENV FLASK_APP fantasy_app.py

# specify app entrypoint + expose port 5000
EXPOSE 5000
ENTRYPOINT [ "python" ]

CMD ["fantasy_application/fantasy_app.py" ]