{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aangine-platform-jaeger.name" -}}
{{- default .Chart.Name .Values.services.jaeger.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aangine-platform-jaeger.fullname" -}}
  {{- $name := required "applicationName is required" .Values.services.jaeger.applicationName -}}
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
{{- define "aangine-platform-jaeger.domainName" -}}
	{{- if (.Values.services.subdomain) -}}
		{{- printf "%s.%s.svc.cluster.local" .Values.services.subdomain .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- else -}}
		{{- printf "%s.svc.cluster.local" .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- end -}}
{{- end -}}


{{- define "aangine-platform-jaeger.storageClassName" -}}
{{- printf "%s-jeager-single-%s-sc" .Values.services.jaeger.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-platform-jaeger.mountPoint" -}}
{{- printf "%s/%s/%s/jaeger/data" .Values.services.jaeger.storage.mountPoint  .Values.services.jaeger.stackName .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aangine-platform-jaeger.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aangine-platform-jaeger.labels" -}}
helm.sh/chart: {{ include "aangine-platform-jaeger.chart" . }}
{{ include "aangine-platform-jaeger.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
stack: {{ printf "%s-%s" .Values.services.jaeger.stackPrefix .Values.services.jaeger.stackName }}
app: {{ .Values.services.jaeger.applicationName }}
tier: {{ .Values.services.jaeger.stackName }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "aangine-platform-jaeger.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aangine-platform-jaeger.name" . }}
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
app.kubernetes.io/component: {{ .Values.services.jaeger.applicationName }}
app.kubernetes.io/name: {{ .Values.services.jaeger.hostname }}
{{- end -}}

{{/*
Create the alternative data volume
*/}}
{{- define "aangine-platform-jaeger.alternativeDataFolder" -}}
    {{ printf "%s/%s/%s" .Values.services.jaeger.storage.hostDataBaseFolder .Release.Namespace .Values.services.jaeger.applicationName }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "aangine-platform-jaeger.serviceAccountName" -}}
  {{- printf "%s-%s-service-account" .Release.Namespace .Values.services.subdomain -}}
{{- end -}}
