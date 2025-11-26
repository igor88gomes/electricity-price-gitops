package main

#
# 1) Ingress must have TLS configured (spec.tls)
#
deny[msg] {
  input.kind == "Ingress"
  not ingress_has_tls
  msg := sprintf(
    "Ingress %q must configure spec.tls with at least one entry",
    [input.metadata.name],
  )
}

ingress_has_tls {
  input.spec.tls
  count(input.spec.tls) > 0
}

#
# 2) Deployment: all containers must define requests/limits for cpu and memory
#
deny[msg] {
  input.kind == "Deployment"
  some i
  container := input.spec.template.spec.containers[i]
  not container_has_resources(container)
  msg := sprintf(
    "Deployment %q container %q must define resources.requests and resources.limits for cpu and memory",
    [input.metadata.name, container.name],
  )
}

container_has_resources(c) {
  c.resources
  c.resources.requests
  c.resources.limits
  c.resources.requests.cpu
  c.resources.requests.memory
  c.resources.limits.cpu
  c.resources.limits.memory
}

#
# 3) Deployment: pods/containers must run as non-root
#    Accept:
#      - spec.template.spec.securityContext.runAsNonRoot = true
#        OR
#      - container.securityContext.runAsNonRoot = true
#
deny[msg] {
  input.kind == "Deployment"
  some i
  container := input.spec.template.spec.containers[i]
  not container_non_root(container, input.spec.template.spec.securityContext)
  msg := sprintf(
    "Deployment %q container %q must set runAsNonRoot=true either at pod or container level",
    [input.metadata.name, container.name],
  )
}

container_non_root(container, pod_sc) {
  pod_sc.runAsNonRoot == true
} else {
  container.securityContext.runAsNonRoot == true
}
