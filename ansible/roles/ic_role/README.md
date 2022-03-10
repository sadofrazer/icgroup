`IC WEBAPP Role`
=========

A light role to install ic webapp app and others intranet application (Odoo + pgadmin) on a remote host via docker. this role need `python-pip and docker-py` prerequistes to run a concaiter with the docker_container module 

Requirements
------------
Note that this  works only on Ubuntu or CentOS Linux distribution
Need to use `sadofrazer.docker_role` to install docker first

Role Variables
--------------

For this role we just have many variables which permit us to modify the name of the remote host if necessary:

  - `PGADMIN_EMAIL`: User email to create the pgadmin instance (default : icgroup@cloudapps-cm.com)
  - `PGADMIN_PASS`: User password to pgadmin instance (default : icgroup)
  - `PGADMIN_PORT`: The port to expose pgadmon application (default : 8082)
  - `DB_USER`:  The postgres database user name (default : odoo)
  - `DB_PASS`: the postgres database password (default : odoo)
  - `DB_NAME`: the postgres database name (default: postgres)
  - `POSTGRES_PORT`: the port number to expose postgres database if need to administarte it with a database administartor tool (default : 5432)
  - `ODOO_PORT`: The port number to expose odoo application (default: 8081)
  - `IC_PORT`: The port number to expose ic webapp application (default: 8080)
  - `HOST_IP`: The ip address of server which host odoo and pgadmin apps (default: 127.0.0.1)
  - `IC_IMAGE_NAME`: default ic webapp image to use (default: sadofrazer/ic-webapp)

Dependencies
------------

Any dependency for this role.

Example Playbook
----------------

Find below an example of playbook to use this role:

    - hosts: servers
      vars:
        instance_name: test
      roles:
         - sadofrazer.docker_role
         - sadofrazer.ic_role

License
-------

NONE

Author Information
------------------

`Frazer SADO`.
