# base image
FROM amazon/aws-lambda-python:3.8

RUN yum install -y git openssh && \
    yum clean all && \
    rm -Rf /var/cache/yum

# download public key for github.com
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# Install poetry:
RUN pip install poetry

# Copy in the config files:
COPY pyproject.toml poetry.lock ./

# Install only dependencies:
RUN poetry config virtualenvs.create false
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt
RUN --mount=type=ssh,id=github_ssh_key pip install -r requirements.txt --no-cache && \
    rm -rf pyproject.toml poetry.lock requirements.txt

COPY ./espn_fantasy_my_matchup ./espn_fantasy_my_matchup

CMD [ "espn_fantasy_my_matchup.handler.handle" ]