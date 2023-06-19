ARG ELK_VERSION

FROM docker.elastic.co/beats/elastic-agent-complete:${ELK_VERSION}

USER root

RUN mkdir state && \
    chown elastic-agent:root /usr/share/elastic-agent/state

USER elastic-agent
