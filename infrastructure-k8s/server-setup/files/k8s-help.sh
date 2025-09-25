#!/bin/bash

cat <<EOF

==========================================
Kubernetes CLI SHORTCUTS & FUNCTIONS HELP
==========================================

Aliases:
+-------+--------------------------+------------------------------+
| Name  | Command                  | What it does                 |
+-------+--------------------------+------------------------------+
| k     | kubectl                  | Main kubectl command         |
| kgp   | kubectl get pods         | List all pods                |
| kgs   | kubectl get svc          | List all services            |
| kgn   | kubectl get nodes        | List all cluster nodes       |
| kga   | kubectl get all          | List all resources           |
| kdp   | kubectl describe pod     | Show details of a pod        |
| kl    | kubectl logs             | Show pod logs                |
| kaf   | kubectl apply -f         | Apply config file            |
| kdf   | kubectl delete -f        | Delete resource from file    |
+-------+--------------------------+------------------------------+

Functions:
+--------+-----------------------------------------+------------------------------------------------------------------+
| Name   | Usage                                   | Description                                                      |
+--------+-----------------------------------------+------------------------------------------------------------------+
| kexec  | kexec <pod> [container]                 | Run an interactive shell in a pod (optionally specify container) |
| klogs  | klogs <pod> [container]                 | Stream logs from a pod (optionally specify container)            |
| kns    | kns                                     | Show current namespace                                           |
|        | kns <namespace>                         | Switch to a different namespace                                  |
| kpf    | kpf <pod> <local-port> <pod-port>       | Port-forward from local to pod                                   |
+--------+-----------------------------------------+------------------------------------------------------------------+

Examples:
  kgp                         # List pods
  kexec my-pod                # Exec into my-pod
  kexec my-pod my-container   # Exec into a specific container
  klogs my-pod                # Tail logs for my-pod
  kns                         # Show current namespace
  kns kube-system             # Switch to kube-system namespace
  kaf deployment.yaml         # Apply a config file

EOF
