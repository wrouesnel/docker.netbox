# promtargets

This is a docker.powerdns-postgres specific utility which connects to the local Postgres-BDR
instance and generates a list of Prometheus monitoring targets based on the number of BDR
nodes attached.

This is to allow each node to reliably monitor its peers. The removal of a node will result
in it being organically deprovisioned from monitoring.

# amquorum

Implements the same logic as promtargets but instead updates an environment file for alertmanager
and forces it to restart.