FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG TEST_IMAGE=false

ENV LC_ALL=C.utf8
ENV LANG=C.utf8

ENV APP_ROOT=/opt/app-root
ENV PIP_NO_CACHE_DIR=1

ENV POETRY_CONFIG_DIR=/opt/app-root/.pypoetry/config
ENV POETRY_DATA_DIR=/opt/app-root/.pypoetry/data
ENV POETRY_CACHE_DIR=/opt/app-root/.pypoetry/cache

ENV UNLEASH_CACHE_DIR=/tmp/unleash_cache

WORKDIR ${APP_ROOT}

RUN microdnf update -y && \
    microdnf install --setopt=install_weak_deps=0 --setopt=tsflags=nodocs -y \
    git-core python39 python39-pip tzdata libpq-devel && \
    rpm -qa | sort > packages-before-devel-install.txt && \
    microdnf install --setopt=tsflags=nodocs -y python39-devel gcc && \
    rpm -qa | sort > packages-after-devel-install.txt

COPY . ${APP_ROOT}/src

WORKDIR ${APP_ROOT}/src

RUN pip3 install --upgrade pip && \
    pip3 install --force-reinstall poetry~=1.5.0 && \
    poetry install --sync

# allows unit tests to run successfully within the container if image is built in "test" environment
RUN if [ "$TEST_IMAGE" = "true" ]; then chgrp -R 0 $APP_ROOT && chmod -R g=u $APP_ROOT; fi

WORKDIR ${APP_ROOT}

RUN microdnf remove -y $( comm -13 packages-before-devel-install.txt packages-after-devel-install.txt ) && \
    rm packages-before-devel-install.txt packages-after-devel-install.txt && \
    microdnf clean all

WORKDIR ${APP_ROOT}/src

CMD poetry run ./run_app.sh
