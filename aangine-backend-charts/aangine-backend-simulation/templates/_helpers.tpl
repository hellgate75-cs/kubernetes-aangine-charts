{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aangine-backend-simulation.name" -}}
{{- default .Chart.Name .Values.services.simulation.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aangine-backend-simulation.fullname" -}}
  {{- $name := required "applicationName is required" .Values.services.simulation.applicationName -}}
  {{- if contains $name .Release.Name -}}
    {{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
Create the definition of the general stack Kubernetes domain.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Kube-Dns default Kubernetes Domain name is composed by subdomain, namespace and a fixed suffix.
*/}}
{{- define "aangine-backend-simulation.domainName" -}}
	{{- if (.Values.services.subdomain) -}}
		{{- printf "%s.%s.svc.cluster.local" .Values.services.subdomain .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- else -}}
		{{- printf "%s.svc.cluster.local" .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aangine-backend-simulation.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aangine-backend-simulation.labels" -}}
helm.sh/chart: {{ include "aangine-backend-simulation.chart" . }}
{{ include "aangine-backend-simulation.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
stack: {{ printf "%s-%s" .Values.services.simulation.stackPrefix .Values.services.simulation.stackName }}
tier: {{ .Values.services.simulation.stackName }}
app: {{ .Values.services.simulation.applicationName }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "aangine-backend-simulation.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aangine-backend-simulation.name" . }}
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
app.kubernetes.io/component: {{ .Values.services.simulation.applicationName }}
app.kubernetes.io/name: {{ .Values.services.simulation.hostname }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "aangine-backend-simulation.serviceAccountName" -}}
  {{- printf "%s-%s-service-account" .Release.Namespace .Values.services.subdomain -}}
{{- end -}}
