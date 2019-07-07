[![Build Status](https://travis-ci.org/wrouesnel/docker.netbox.svg?branch=master)](https://travis-ci.org/wrouesnel/docker.netbox)

# Netbox Container for Standalone Deployment

This is a self-contained container which builds and deploys Netbox.

## New Deployment Instructions

1. Stand up the container.
1. Run database migrations.
1. Create a superuser.

## LDAP Parameters

## WebUI Hooks

The following webui hooks are available to carry out container operations,
protected behind the admin interface and require POST commands:

* `/container/api/netbox-migrate`
  Perform database migrations.

* `/container/api/netbox-createsuperuser`
  Create super users in the backend DB. Accepts a JSON object with the user
  parameters - example:
  ```json
    {
	    "username" : "superadmin",
	    "password" : "superpassword",
	    "email" : "superadmin@superdomain.supertld"
    }
  ```
  
* `/container/api/binary-backup`
  Generate and stream a tar file containing all the netbox specific user data.
  
* `/container/api/dump-data`
  Execute the Django dumpdata command which dumps the database as JSON.

## Environment Variables

* `HOSTNAME`
  Persistent hostname of this node. If unset defaults to the docker hostname.
  This is used as the `nodename` for all CockroachDB replication operations.

* `ADMIN_USER=admin`
  Username of the admin user for accessing online management functions of the
  container (namely, the WebUI of alertmanager and cockroachdb).

* `ADMIN_PASSWORD`
  Password of the admin user for accessing online management functions of the
  container (namely, the WebUI of alertmanager and cockroachdb).

* `WEBUI_SSL_SERVER_CERT=`
  WebUI server identity certificate. May be a literal PEM certificate or a file path
  inside the container.
* `WEBUI_SSL_SERVER_KEY=`
  WebUI server identity key. May be a literal PEM certificate or a file path
  inside the container.
* `WEBUI_SSL_SERVER_CERTCHAIN=`
  WebUI server identity certificate chain. May be a literal PEM certificate or a file path
  inside the container.

* `PSQL_USER=psql`
  PostgreSQL user to create on database initialization.

* `PSQL_PASSWORD=`
  PostgreSQL password to create for the user. If not specified, a random one is
  generated and saved.
  
* `PSQL_DB=psql_db`
  PostgreSQL database to create if database is being initialized. If not specified
  then the value of `${PSQL_USER}_db` will be used.

* `PSQL_SSL_SERVER_CERT=`
  PostgreSQL server identity certificate. May be a literal PEM certificate or a file path
  inside the container.
* `PSQL_SSL_SERVER_KEY=`
  PostgreSQL server identity key. May be a literal PEM certificate or a file path
  inside the container.
* `PSQL_SSL_SERVER_CERTCHAIN=`
  PostgreSQL server identity certificate chain. May be a literal PEM certificate or a file path
  inside the container.
* `PSQL_SSL_CLIENT_CACERT=`
  PostgreSQL client certificate authority. It is recommended two certificates
  be present to allow for rolling trust changes.
* `PSQL_SSL_CLIENT_CERT=`
  PostgreSQL client authentication certificate. This *must* have a commonName 
  (CN) that matches the value given for the `PSQL_USER`.
* `PSQL_SSL_CLIENT_KEY=`
  PostgreSQL client authentication certificate. This *must* have a commonName 
  (CN) that matches the value given for the `PSQL_USER`.

* `SMTP_SMARTHOST=`
  `hostname:port` to use for sending alert emails.
* `SMTP_FROM`
  from address to set for from emails. If unset, defaults to `alerts@{{API_DNS_NAME}}`
* `SMTP_USERNAME=`
  username to use to login to the SMTP server.
* `SMTP_PASSWORD=`
  password to use to login to the SMTP server.
  
  
* `NTP_SERVER=127.0.0.1`
  NTP server to use for Prometheus NTP monitoring.
* `ALERT_EMAIL_ADDRESS=`
  email address to send alerts to.
  
  
* `DEV_ALLOW_SELF_SIGNED=no`
  Allows a blank value for `SSL_SERVER_CERT` and `SSL_SERVER_KEY`. This causes
  the container to generate a self-signed certificate on startup. It is not a
  production configuration, but useful for development.
* `DEV_ALLOW_EPHEMERAL_DATA=no`
  Normally the container explicitely disallows ephemeral storge. This option
  overrides the check if set to `yes` to allow `/data` to not be a mountpoint.
* `DEV_STANDALONE=no`
  Disables any SSL client certificate checks and forces the node to trust only
  its local certificate. Useful for testing when using the standalone schema.
* `DEV_ALLOW_DEFAULT_TRUST=no`
  Set to `yes` to allow default platform SSL certificates to be used if
  `PLATFORM_TLS_TRUST_CERTIFICATES` is blank.
* `DEV_NO_ALERT_EMAILS=no`
  Set to `yes` to allow no addresses for sending alert emails to be specified.
* `DEV_NO_SMARTHOST=no`
  Set to `yes` to allow no the SMTP smarthost to be blank.
* `DEV_NO_SMARTHOST_TLS=no`
  Set to `yes` to disable TLS for smarthosts.
* `DEV_ENTRYPOINT_DEBUG=no"
  Set to `yes` to set `bash -x` on the entrypoint. 

* `DEV_NETBOX_DEBUG=no` when set to yes, forces django debugging to `True` which
  yields more debugging error messages. Do not use in production.

These settings are only usable if the container is built with `PYTHON_REMOTE_DEBUGGING=yes`
at build time. Otherwise they are defined, but harmless.

* `DEV_NETBOX_REMOTE_DEBUG_HOST=0.0.0.0` Set the address for the remote debugger to listen on.
* `DEV_NETBOX_REMOTE_DEBUG_PORT=51234` Set the port for the debugger to listen on.
* `DEV_NETBOX_REMOTE_DEBUG_ENABLE=no` Enable the remote debugger port.

* `NETBOX_WEB_SECRET=`
  Web secret for client tokens. Leave blank to randomly generate. Only needs to be
  set if clustering.

* `NETBOX_CHANGELOG_RETENTION_DAYS=0`
  Number of days to retain changelog changes. 0 for infinity.

* `NETBOX_PREFIX_PATH=`
  Path prefix netbox is being hosted under. Use only if reverse proxying behind a prefix.

* `NETBOX_ADMIN_EMAIL=`
  If set, becomes an email which Netbox will send notifications too using the SMTP settings.
  This is different then the alert system.

* `NETBOX_ADMIN_NAME="Netbox Admin"`
  Name of the Netbox admin in emails. No need to change generally.

* `NETBOX_TIMEZONE=UTC`
  Timezone for Netbox.

* `NETBOX_LDAP_AUTH=yes`
  enable LDAP auth. Otherwise it is disabled.

* `NETBOX_LDAP_SERVER_URI=`
  URI for one or more LDAP servers, space separated - e.g. `ldaps://myserver:636`

* `NETBOX_LDAP_SERVER_BIND_DN=`
  DN to use for the bind account for LDAP.

* `NETBOX_LDAP_SERVER_BIND_PASSWORD=`
  Password to use for the bind DN.

* `NETBOX_LDAP_USER_BASE_DN`
  Base DN to search under to bind users when using a bind account.

* `NETBOX_LDAP_USER_SEARCH_FILTER`
  Search filter for users when using a bind account.

* `NETBOX_LDAP_USER_DN_TEMPLATE=` - If specified, serves as a template for 
  binding users (and skips the need for a bind account). An example of its
  form would be `cn=%(user)s,OU=SomeOu,DC=example,DC=com`
  
* `NETBOX_LDAP_GROUP_BASE_DN`
  Base DN to search for user groups under.

* `NETBOX_LDAP_GROUP_SEARCH_FILTER=(objectCategory=Group)`
  Search filter for user groups.

* `NETBOX_LDAP_GROUP_REQUIRED_DN`
  DN of a group a user must be a part of to authenticate.

* `NETBOX_LDAP_GROUP_USER_ACTIVE_DN`
  DN a user must be a part of to be able to login at all.

* `NETBOX_LDAP_GROUP_USER_STAFF_DN`
  DN a user must be a part of to gain write access.

* `NETBOX_LDAP_GROUP_USER_SUPERUSER_DN`
  DN a user must be a part of to gain super-user powers.

## Hacking

`make run-it` to startup the container with most dev options enabled.
`make enter-it` to override the entrypoint and get a shell.
`make exec-into` will try and start a shell in an already running container.
