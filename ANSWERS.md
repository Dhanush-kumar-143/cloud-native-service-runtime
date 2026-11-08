\# Gateway API Migration Strategy



I would migrate the 40 ingress-nginx objects incrementally rather than replacing the controller in one operation.



First, I would inventory the existing Ingress resources, annotations, TLS settings, path rules, rewrites, timeouts, and controller-specific behavior. I would group them by application and complexity, identify dependencies, and map supported features to Gateway API resources such as Gateway, HTTPRoute, and TLSRoute where appropriate.



Next, I would install a Gateway API-compatible controller alongside ingress-nginx. I would create the required GatewayClass and Gateway resources, then convert a small set of representative routes. I would validate routing, hostname matching, path handling, TLS certificates, redirects, timeouts, and backend health in staging.



For production, I would run both controllers in parallel. I would move a low-risk application first, verify logs and metrics, and then shift traffic in controlled batches using DNS or the available load-balancing layer. I would define success criteria for error rates, latency, and availability before each batch.



Potential breakages include unsupported ingress-nginx annotations, rewrite behavior, timeout differences, TLS configuration, and controller-specific defaults. I would test these explicitly and document required changes.



Rollback would keep the original Ingress resources and ingress-nginx controller available throughout the migration. If a batch failed its health criteria, I would route traffic back to the original controller, investigate, and retry only after validation. I would decommission ingress-nginx only after all routes had migrated successfully and completed an agreed bake period.
