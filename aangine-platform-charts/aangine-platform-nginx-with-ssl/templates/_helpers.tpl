{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aangine-platform-nginx-with-ssl.name" -}}
{{- default .Chart.Name .Values.services.nginx.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aangine-platform-nginx-with-ssl.fullname" -}}
  {{- $name := required "applicationName is required" .Values.services.nginx.applicationName -}}
  {{- if contains $name $.Release.Name -}}
    {{- printf "%s-with-ssl" $.Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s-with-ssl" $.Release.Name $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
Create the definition of the general stack Kubernetes domain.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Kube-Dns default Kubernetes Domain name is composed by subdomain, namespace and a fixed suffix.
*/}}
{{- define "aangine-platform-nginx-with-ssl.domainName" -}}
	{{- if (.Values.services.subdomain) -}}
		{{- printf "%s.%s.svc.cluster.local" .Values.services.subdomain .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- else -}}
		{{- printf "%s.svc.cluster.local" .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- end -}}
{{- end -}}

{{- define "aangine-platform-nginx-with-ssl.hostNgnixConfigPath" -}}
  {{- if .Values.services.nginx.useNoAuth -}}
    {{- printf "%s/templates/%s" .Values.services.nginx.storage.hostConfigFolder .Values.services.nginx.storage.configFileNoAuth -}}
  {{- else -}}
	  {{- if .Values.services.nginx.useUI -}}
		{{- printf "%s/templates/%s" .Values.services.nginx.storage.hostConfigFolder .Values.services.nginx.storage.configFileUI -}}
	  {{- else -}}
		{{- printf "%s/templates/%s" .Values.services.nginx.storage.hostConfigFolder .Values.services.nginx.storage.configFileNoUI -}}
	  {{- end -}}
  {{- end -}}
{{- end -}}


{{- define "aangine-platform-nginx-with-ssl.hostNgnixTemplatesApiDocPath" -}}
  {{- printf "%s/templates/api-doc.html" .Values.services.nginx.storage.hostConfigFolder -}}
{{- end -}}


{{- define "aangine-platform-nginx-with-ssl.hostNgnixTemplatesGetHtpasswdPath" -}}
  {{- printf "%s/templates/get/.htpasswd" .Values.services.nginx.storage.hostConfigFolder -}}
{{- end -}}


{{- define "aangine-platform-nginx-with-ssl.hostNgnixTemplatesSetHtpasswdPath" -}}
  {{- printf "%s/templates/set/.htpasswd" .Values.services.nginx.storage.hostConfigFolder -}}
{{- end -}}

{{- define "aangine-platform-nginx-with-ssl.hostNgnixTemplatesCertsPath" -}}
  {{- printf "%s/aangine-certs" .Values.services.nginx.storage.hostConfigFolder -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aangine-platform-nginx-with-ssl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aangine-platform-nginx-with-ssl.labels" -}}
helm.sh/chart: {{ include "aangine-platform-nginx-with-ssl.chart" . }}
{{ include "aangine-platform-nginx-with-ssl.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ $.Release.Service }}
stack: {{ printf "%s-%s" .Values.services.nginx.stackPrefix .Values.services.nginx.stackName }}
tier: {{ .Values.services.nginx.stackName }}
app: {{ .Values.services.nginx.applicationName }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "aangine-platform-nginx-with-ssl.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aangine-platform-nginx-with-ssl.name" . }}
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
app.kubernetes.io/component: {{ .Values.services.nginx.applicationName }}
app.kubernetes.io/name: {{ .Values.services.nginx.hostname }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "aangine-platform-nginx-with-ssl.serviceAccountName" -}}
  {{- printf "%s-%s-service-account" .Release.Namespace .Values.services.subdomain -}}
{{- end -}}
