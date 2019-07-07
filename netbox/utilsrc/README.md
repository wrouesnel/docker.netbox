# Utility binaries for docker.powerdns-postgres

Golang utility binaries for handling aspects of the powerdns image.

Dependencies are fully vendored with [`govendor`](https://github.com/kardianos/govendor)

Current utilities:

* `promtargets` - Poller which extracts a list of monitoring targets from the list of
  replication peers in Postgres-BDR and updates Prometheus file_sd_configs.
