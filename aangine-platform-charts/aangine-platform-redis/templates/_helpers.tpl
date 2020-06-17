{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aangine-platform-redis.name" -}}
{{- default .Chart.Name .Values.services.redis.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aangine-platform-redis.fullname" -}}
  {{- $name := required "applicationName is required" .Values.services.redis.applicationName -}}
  {{- if contains $name .Release.Name -}}
    {{- printf "%s-single" .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s-single" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
Create the definition of the general stack Kubernetes domain.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Kube-Dns default Kubernetes Domain name is composed by subdomain, namespace and a fixed suffix.
*/}}
{{- define "aangine-platform-redis.domainName" -}}
	{{- if (.Values.services.subdomain) -}}
		{{- printf "%s.%s.svc.cluster.local" .Values.services.subdomain .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- else -}}
		{{- printf "%s.svc.cluster.local" .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aangine-platform-redis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "aangine-platform-redis.storageClassName" -}}
{{- printf "%s-redis-single-%s-sc" .Values.services.redis.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "aangine-platform-redis.mountPoint" -}}
{{- printf "%s/%s/%s/redis/data" .Values.services.redis.storage.mountPoint  .Values.services.redis.stackName .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Common labels
*/}}
{{- define "aangine-platform-redis.labels" -}}
helm.sh/chart: {{ include "aangine-platform-redis.chart" . }}
{{ include "aangine-platform-redis.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
stack: {{ printf "%s-%s" .Values.services.redis.stackPrefix .Values.services.redis.stackName }}
tier: {{ .Values.services.redis.stackName }}
app: {{ .Values.services.redis.applicationName }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "aangine-platform-redis.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aangine-platform-redis.name" . }}
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
app.kubernetes.io/component: {{ .Values.services.redis.applicationName }}
app.kubernetes.io/name: {{ .Values.services.redis.hostname }}
{{- end -}}

{{/*
Create the alternative data volume
*/}}
{{- define "aangine-platform-redis.alternativeDataFolder" -}}
    {{ printf "%s/%s/%s" .Values.services.redis.storage.hostDataBaseFolder .Release.Namespace .Values.services.redis.applicationName }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "aangine-platform-redis.serviceAccountName" -}}
  {{- printf "%s-%s-service-account" .Release.Namespace .Values.services.subdomain -}}
{{- end -}}
