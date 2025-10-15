
# Install Traefik
```
helm upgrade --install traefik traefik-repo/traefik --namespace traefik --create-namespace -f values.yaml
```
# Update domain name for new load balancer

```
kubectl get svc -n traefik
```

Create CNAME/A/AAA for Load balancer name. Lets encrypt works fine with CNAME.

