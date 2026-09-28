{{/*
Expand the name of the chart.
*/}}
{{- define "loginset.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "loginset.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "loginset.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Per-login-set labels, mirroring soperator's common.RenderLabels (app.kubernetes.io/*
with name=slurmcluster, managed-by=slurm-operator) plus a per-set label so multiple
login sets can coexist. Pass (rootContext, setValues).
*/}}
{{- define "loginset.setLabels" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
app.kubernetes.io/name: slurmcluster
app.kubernetes.io/instance: {{ $root.Values.clusterName | default $root.Release.Name }}
app.kubernetes.io/component: loginset
app.kubernetes.io/part-of: slurm-operator
app.kubernetes.io/managed-by: slurm-operator
loginset.fptcloud.com/set: {{ $set.name | quote }}
{{- with ($set.labels | default dict) }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Per-login-set selector labels, mirroring soperator's common.RenderMatchLabels plus
the per-set label. Pass (rootContext, setValues).
*/}}
{{- define "loginset.setSelectorLabels" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
app.kubernetes.io/name: slurmcluster
app.kubernetes.io/instance: {{ $root.Values.clusterName | default $root.Release.Name }}
app.kubernetes.io/component: loginset
loginset.fptcloud.com/set: {{ $set.name | quote }}
{{- end }}

{{/*
Resolve an image string ("repo:tag") from a per-set override falling back to root images.
Pass (rootContext, setImageBlock, containerName) where setImageBlock is the per-container
{repository, tag} block (may be empty/nil) and containerName is one of sshd/munge/sssd.
*/}}
{{- define "loginset.image" -}}
{{- $root := index . 0 -}}
{{- $img := index . 1 -}}
{{- $containerName := index . 2 -}}
{{- $default := get $root.Values.images $containerName -}}
{{- $repo := default $default.repository (($img | default dict).repository) -}}
{{- $tag := default $default.tag (($img | default dict).tag) -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end }}

{{/*
Resolve imagePullPolicy for a container. Pass (setImageBlock, default).
*/}}
{{- define "loginset.pullPolicy" -}}
{{- $img := index . 0 -}}
{{- $default := index . 1 -}}
{{- default $default (($img | default dict).pullPolicy) -}}
{{- end }}

{{/*
clusterName used for deriving soperator-style resource names.
*/}}
{{- define "loginset.clusterName" -}}
{{- .Values.clusterName | default .Release.Name -}}
{{- end }}

{{/*
StatefulSet name for a login set. Mirrors naming.BuildNodeSetStatefulSetName which
uses just the component specifier as the name. Truncated to 63.
*/}}
{{- define "loginset.statefulSetName" -}}
{{- $set := index . 1 -}}
{{- $set.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
sshd Service name for a login set, mirroring naming.BuildServiceName(login, clusterName)
= clusterName-login-svc, disambiguated per set.
*/}}
{{- define "loginset.sshdServiceName" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
{{- printf "%s-login-svc-%s" (include "loginset.clusterName" $root) $set.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Per-login-set headless Service name: clusterName-login-<setName>-headless-svc.
Each StatefulSet points its serviceName at its own headless service so pods get
stable per-set DNS names (stsName-ordinal.svc) and DNS discovery stays within the set.
Pass (rootContext, setValues).
*/}}
{{- define "loginset.headlessServiceName" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
{{- printf "%s-login-%s-headless-svc" (include "loginset.clusterName" $root) $set.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
munge key Secret name: user-supplied, else soperator's BuildSecretMungeKeyName =
clusterName-munge.
*/}}
{{- define "loginset.mungeKeySecretName" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
{{- if ($set.mungeKeySecretName | default "") }}
{{- $set.mungeKeySecretName -}}
{{- else }}
{{- printf "%s-munge" (include "loginset.clusterName" $root) -}}
{{- end }}
{{- end }}

{{/*
sshd host keys Secret name: user-supplied, else soperator's BuildSecretSSHDKeysName =
clusterName-sshd-keys.
*/}}
{{- define "loginset.sshdKeysSecretName" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
{{- if ($set.sshdKeysSecretName | default "") }}
{{- $set.sshdKeysSecretName -}}
{{- else }}
{{- printf "%s-sshd-keys" (include "loginset.clusterName" $root) -}}
{{- end }}
{{- end }}

{{/*
security-limits ConfigMap name: user-supplied, else soperator's
BuildConfigMapSecurityLimitsName(login, clusterName) = clusterName-login-security-limits.
*/}}
{{- define "loginset.securityLimitsCMName" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
{{- if ($set.securityLimitsConfigMapName | default "") }}
{{- $set.securityLimitsConfigMapName -}}
{{- else }}
{{- printf "%s-login-security-limits" (include "loginset.clusterName" $root) -}}
{{- end }}
{{- end }}

{{/*
sshd-configs ConfigMap name: user-supplied, else soperator's
BuildConfigMapSSHDConfigsNameLogin(clusterName) = clusterName-ssh-configs.
*/}}
{{- define "loginset.sshdConfigsCMName" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
{{- if ($set.sshdConfigMapName | default "") }}
{{- $set.sshdConfigMapName -}}
{{- else }}
{{- printf "%s-ssh-configs" (include "loginset.clusterName" $root) -}}
{{- end }}
{{- end }}

{{/*
sssd Conf Secret name: user-supplied, else soperator's BuildSecretSSSDConfName =
clusterName-sssd-conf.
*/}}
{{- define "loginset.sssdConfSecretName" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
{{- if ($set.sssdConfSecretRefName | default "") }}
{{- $set.sssdConfSecretRefName -}}
{{- else }}
{{- printf "%s-sssd-conf" (include "loginset.clusterName" $root) -}}
{{- end }}
{{- end }}

{{/*
Resolves to "true" when the chart should render the ssh-root-keys ConfigMap, "false"
when the user points at an external one. Pass (rootContext, set).
*/}}
{{- define "loginset.useDefaultSshRootKeysCM" -}}
{{- $set := index . 1 -}}
{{- if ($set.sshRootPublicKeysExternal | default false) }}false{{- else }}true{{- end -}}
{{- end }}

{{/*
Name of the ssh-root-public-keys ConfigMap. The chart renders one per login set by
default (named <cluster>-ssh-root-keys-<setName>, or sshRootPublicKeysConfigMapName
when provided). Set sshRootPublicKeysExternal: true to skip rendering and reference an
existing ConfigMap instead.
*/}}
{{- define "loginset.sshRootKeysCMName" -}}
{{- $root := index . 0 -}}
{{- $set := index . 1 -}}
{{- if ($set.sshRootPublicKeysConfigMapName | default "") }}
{{- $set.sshRootPublicKeysConfigMapName -}}
{{- else }}
{{- printf "%s-ssh-root-keys-%s" (include "loginset.clusterName" $root) $set.name | trunc 63 | trimSuffix "-" -}}
{{- end }}
{{- end }}

{{/*
Resources for a container, mirroring soperator's pattern:
Requests = the values map; Limits = the same except CPU (CopyNonCPUResources),
unless cpuLimit is provided. Pass (resourceMap, cpuLimit).
*/}}
{{- define "loginset.resources" -}}
{{- $r := index . 0 | default dict -}}
{{- $cpuLimit := index . 1 -}}
requests:
  {{- range $k, $v := $r }}
  {{- if eq $k "cpuLimit" }}
  {{- else if eq $k "ephemeralStorage" }}
  ephemeral-storage: {{ $v | quote }}
  {{- else }}
  {{ $k }}: {{ $v | quote }}
  {{- end }}
  {{- end }}
limits:
  {{- with $cpuLimit }}
  cpu: {{ . | quote }}
  {{- end }}
  {{- range $k, $v := $r }}
  {{- if eq $k "cpu" }}
  {{- else if eq $k "cpuLimit" }}
  {{- else if eq $k "ephemeralStorage" }}
  ephemeral-storage: {{ $v | quote }}
  {{- else }}
  {{ $k }}: {{ $v | quote }}
  {{- end }}
  {{- end }}
{{- end }}
