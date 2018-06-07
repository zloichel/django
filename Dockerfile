FROM python:3.5-alpine

ADD requirements.txt /requirements.txt

RUN set -ex \
    && apk add --no-cache --virtual .build-deps \
            gcc \
            make \
            libc-dev \
            musl-dev \
            linux-headers \
            pcre-dev \
    && pyvenv /venv \
    && /venv/bin/pip install -U pip \
    && LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "/venv/bin/pip install --no-cache-dir -r /requirements.txt" \
    && runDeps="$( \
            scanelf --needed --nobanner --recursive /venv \
                    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                    | sort -u \
                    | xargs -r apk info --installed \
                    | sort -u \
    )" \
    && apk add --virtual .python-rundeps $runDeps \
    && apk del .build-deps


RUN apk add --no-cache bash

RUN mkdir /code/
WORKDIR /code/
ADD . /code/


EXPOSE 8000

RUN python setup.py install
RUN django/bin/django-admin.py startproject mysite
RUN sed -i -e "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \[\'23.111.231.70\'\]/g" mysite/mysite/settings.py
CMD ["python", "mysite/manage.py", "runserver", "0.0.0.0:8000"]
