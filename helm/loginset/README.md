# Soperator LoginSet helm chart

This helm chart deploys multiple sets of Slurm login nodes. Each login set renders:

- one OpenKruise `StatefulSet` (apps.kruise.io/v1beta1)
- one sshd `Service` (LoadBalancer or NodePort)
- one ssh-root-public-keys `ConfigMap` (when the user did not supply their own)
- one `HorizontalPodAutoscaler` (when `hpa.enabled` is true)

The StatefulSet's `serviceName` points at the headless Service the soperator controller already
creates for the parent `SlurmCluster` (`<clusterName>-login-headless-svc`); this chart does not
render its own headless service, and the cluster's login headless service selector already
matches these pods.

The StatefulSet, pod spec, volumes and container definitions mirror exactly what the soperator
controller renders for the `login` block of a `SlurmCluster` (see
`internal/render/login/statefulset.go`, `container.go`, `volume.go`), so the resulting pods are
drop-in compatible with a soperator-managed login node — only the workload controller (Helm vs.
soperator) differs. Unlike the login block embedded in the `slurm-cluster` chart (which renders a
single login configuration inside the `SlurmCluster` CR), this chart is pure Helm and does not
require a new CRD.

### Prerequisites

- OpenKruise must be installed in the cluster (the `soperator` chart already depends on it; see
  `soperator/Chart.yaml`). The StatefulSet uses `apps.kruise.io/v1beta1`.

### Backing resources

The soperator controller normally derives several backing resources for a `SlurmCluster` of a
given name. This chart assumes those already exist (created by the operator for the parent
SlurmCluster) and references them by the same derived names, by default:

- `<clusterName>-munge-key` — Secret holding the munge key
- `<clusterName>-sshd-keys` — Secret holding the sshd host keys
- `<clusterName>-login-security-limits` — ConfigMap holding `limits.conf`
- `<clusterName>-login-ssh-configs` — ConfigMap holding sshd configs

Each of these can be overridden per login set via `mungeKeySecretName`,
`sshdKeysSecretName`, `securityLimitsConfigMapName`, `sshdConfigMapName`. The ssh-root-public-keys
ConfigMap is created by this chart (one per login set) from each set's `sshRootPublicKeys` unless
`sshRootPublicKeysConfigMapName` is supplied.

### To install / update:

```bash
helm upgrade -n soperator --install loginsets ./loginset
```

### To delete:

```bash
helm uninstall -n soperator loginsets
```

### Configuration

`values.yaml` defines a `loginsets` list. Each entry mirrors the login block of the
`slurm-cluster` chart and adds an `hpa` block:

```yaml
clusterName: "fpt-hpc"
clusterWithGPU: false

loginsets:
  - name: login-default
    size: 1
    sshd:
      resources: { cpu: "3000m", memory: "64Gi", ephemeralStorage: "30Gi" }
    sshRootPublicKeys:
      - "ssh-ed25519 AAAA..."
    sshdServiceType: LoadBalancer
    munge:
      resources: { cpu: "500m", memory: "500Mi", ephemeralStorage: "5Gi" }
    volumes:
      jail: { volumeSourceName: "jail" }
      jailSubMounts: []
      customMounts: []
    hpa:
      enabled: true
      minReplicas: 1
      maxReplicas: 3
      metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 80
      behavior: {}
```

When `hpa.enabled` is false (the default), the `StatefulSet` uses `size` replicas. When
`hpa.enabled` is true, the HPA owns the replica count and `spec.replicas` is omitted from the
StatefulSet.
