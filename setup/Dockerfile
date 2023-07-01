ARG ELASTIC_VERSION

# https://www.docker.elastic.co/
FROM docker.elastic.co/elasticsearch/elasticsearch:${ELASTIC_VERSION}

USER root

COPY . /

RUN set -eux; \
	mkdir /state; \
	chown elasticsearch /state; \
	chmod +x /entrypoint.sh 

RUN set -eux; \
	mkdir /usr/share/elasticsearch/config/certs; \
	chown elasticsearch:root /usr/share/elasticsearch/config/certs

USER elasticsearch:root

ENTRYPOINT ["/entrypoint.sh"]
