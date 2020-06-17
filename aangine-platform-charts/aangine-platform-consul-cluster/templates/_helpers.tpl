{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aangine-platform-consul-cluster.name" -}}
{{- default .Chart.Name .Values.services.consul.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aangine-platform-consul-cluster.fullname" -}}
  {{- $name := required "applicationName is required" .Values.services.consul.applicationName -}}
  {{- if contains $name .Release.Name -}}
    {{- printf "%s-cluster" .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s-cluster" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
Create the definition of the general stack Kubernetes domain.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Kube-Dns default Kubernetes Domain name is composed by subdomain, namespace and a fixed suffix.
*/}}
{{- define "aangine-platform-consul-cluster.domainName" -}}
	{{- if (.Values.services.subdomain) -}}
		{{- printf "%s.%s.svc.cluster.local" .Values.services.subdomain .Release.Namespace | trunc 124 | trimSuffix "-" -}}
	{{- else -}}
		{{- printf "%s.svc.cluster.local" .Release.Namespace | trunc 124 | trimSuffix "-" -}}
	{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aangine-platform-consul-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-platform-consul-cluster.storageClassName" -}}
{{- printf "%s-consul-cluster-%s-1-sc" .Values.services.consul.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-platform-consul-cluster.secondStorageClassName" -}}
{{- printf "%s-consul-cluster-%s-2-sc" .Values.services.consul.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-platform-consul-cluster.thirdStorageClassName" -}}
{{- printf "%s-consul-cluster-%s-3-sc" .Values.services.consul.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-platform-consul-cluster.mountPoint" -}}
{{- printf "%s/%s/%s/consul/cluster/node1/data" .Values.services.consul.storage.mountPoint  .Values.services.consul.stackName .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-platform-consul-cluster.secondMountPoint" -}}
{{- printf "%s/%s/%s/consul/cluster/node1/data" .Values.services.consul.storage.mountPoint  .Values.services.consul.stackName .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-platform-consul-cluster.thirdMountPoint" -}}
{{- printf "%s/%s/%s/consul/cluster/node1/data" .Values.services.consul.storage.mountPoint  .Values.services.consul.stackName .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aangine-platform-consul-cluster.labels" -}}
helm.sh/chart: {{ include "aangine-platform-consul-cluster.chart" . }}
{{ include "aangine-platform-consul-cluster.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
stack: {{ printf "%s-%s" .Values.services.consul.stackPrefix .Values.services.consul.stackName }}
tier: {{ .Values.services.consul.stackName }}
app: {{ .Values.services.consul.applicationName }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "aangine-platform-consul-cluster.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aangine-platform-consul-cluster.name" . }}
{{- if $.Release.Name }}
app.kubernetes.io/instance: "{{ $.Release.Name }}"
{{- end }}
{{- if $.Chart.AppVersion }}
app.kubernetes.io/version: {{ $.Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.services.subdomain }}
app.kubernetes.io/domain: {{ .Values.services.subdomain }}
{{- end }}
app.kubernetes.io/namespace: {{ .Release.Namespace }}
app.kubernetes.io/component: {{ .Values.services.consul.applicationName }}
app.kubernetes.io/name: {{ .Values.services.consul.hostname }}
{{- end -}}

{{/*
Create the alternative data volume
*/}}
{{- define "aangine-platform-consul-cluster.alternativeDataFolder" -}}
    {{ printf "%s/%s/%s/cluster" .Values.services.consul.storage.hostDataBaseFolder .Release.Namespace .Values.services.consul.applicationName }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "aangine-platform-consul-cluster.serviceAccountName" -}}
  {{- printf "%s-%s-service-account" .Release.Namespace .Values.services.subdomain -}}
{{- end -}}
