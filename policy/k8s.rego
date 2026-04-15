package main

# Ingress must define TLS in spec.tls.
deny contains msg if {
  input.kind == "Ingress"
  not ingress_has_tls
  msg := sprintf(
    "Ingress %q must configure spec.tls with at least one entry",
    [input.metadata.name],
  )
}

ingress_has_tls if {
  input.spec.tls
  count(input.spec.tls) > 0
}

# All Deployment containers must define cpu and memory requests and limits.
deny contains msg if {
  input.kind == "Deployment"
  some i
  container := input.spec.template.spec.containers[i]
  not container_has_resources(container)
  msg := sprintf(
    "Deployment %q container %q must define resources.requests and resources.limits for cpu and memory",
    [input.metadata.name, container.name],
  )
}

container_has_resources(c) if {
  c.resources
  c.resources.requests
  c.resources.limits
  c.resources.requests.cpu
  c.resources.requests.memory
  c.resources.limits.cpu
  c.resources.limits.memory
}

# Deployment containers must run as non-root.
# Accepted configuration:
# - spec.template.spec.securityContext.runAsNonRoot = true
# - container.securityContext.runAsNonRoot = true
deny contains msg if {
  input.kind == "Deployment"
  some i
  container := input.spec.template.spec.containers[i]
  not container_non_root(container, input.spec.template.spec.securityContext)
  msg := sprintf(
    "Deployment %q container %q must set runAsNonRoot=true either at pod or container level",
    [input.metadata.name, container.name],
  )
}

# Pod-level runAsNonRoot.
container_non_root(container, pod_sc) if {
  pod_sc.runAsNonRoot == true
}

# Container-level runAsNonRoot.
container_non_root(container, pod_sc) if {
  not pod_sc.runAsNonRoot
  container.securityContext.runAsNonRoot == true
}