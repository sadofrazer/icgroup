FROM python:3.6-alpine

LABEL Maintainer="sadofrazer"
LABEL email="sadofrazer@yahoo.fr"

WORKDIR /opt

RUN pip install flask==1.1.2 

COPY ./app_files/ /opt/

ENV ODOO_URL='https://www.odoo.com/'
ENV PGADMIN_URL='https://WWW.pgadmin.org/'

EXPOSE 8080

ENTRYPOINT ["python", "app.py"]
