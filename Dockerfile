FROM odoo:12.0

USER root

RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
         build-essential \
         gosu \
         git \
         gcc \
         gnupg2 \
         make \
         libxml2 \
         libxslt-dev \
         python3-dev

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' >  /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && apt-get install -y --no-install-recommends postgresql-client-12 libpq-dev && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade setuptools wheel
RUN pip install git+https://github.com/OCA/openupgradelib xades xmltodict zeep

# https://github.com/OCA/maintainer-quality-tools/pull/404
ENV MQT_URI="https://github.com/arkhan/maintainer-quality-tools/archive/master.tar.gz"
RUN curl -sL "$MQT_URI" | tar -xz -C /opt/ \
    && ln -sf /opt/maintainer-quality-tools-*/travis/clone_oca_dependencies /usr/bin \
    && ln -sf /opt/maintainer-quality-tools-*/travis/getaddons.py /usr/bin \
    && chmod +x /usr/bin/getaddons.py

COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh
