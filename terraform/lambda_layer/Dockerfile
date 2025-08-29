FROM public.ecr.aws/lambda/python:3.9

RUN yum install -y zip

WORKDIR /layer
RUN pip install psycopg2-binary -t ./python/lib/python3.9/site-packages

RUN zip -r /tmp/psycopg2-layer.zip python