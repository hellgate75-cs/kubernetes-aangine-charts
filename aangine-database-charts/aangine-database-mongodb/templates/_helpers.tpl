{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aangine-databasemongodb.name" -}}
{{- default .Chart.Name .Values.services.mongodb.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aangine-databasemongodb.fullname" -}}
  {{- $suffix := "single" -}}
  {{- if .Values.services.mongodb.enableCluster }}
	{{- $suffix := "cluster" -}}
  {{- end -}}
  {{- $name := required "applicationName is required" .Values.services.mongodb.applicationName -}}
  {{- if contains $name .Release.Name -}}
    {{- printf "%s-%s" .Release.Name $suffix | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s-%s" .Release.Name $name $suffix | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
Create the definition of the general stack Kubernetes domain.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Kube-Dns default Kubernetes Domain name is composed by subdomain, namespace and a fixed suffix.
*/}}
{{- define "aangine-databasemongodb.domainName" -}}
	{{- if (.Values.services.subdomain) -}}
		{{- printf "%s.%s.svc.cluster.local" .Values.services.subdomain .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- else -}}
		{{- printf "%s.svc.cluster.local" .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aangine-databasemongodb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-databasemongodb.storageClassName" -}}
{{- printf "%s-mongo-%s-db-sc" .Values.services.mongodb.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "aangine-databasemongodb.configStorageClassName" -}}
{{- printf "%s-mongo-%s-db-config-sc" .Values.services.mongodb.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-databasemongodb.pathProvisionerRef" -}}
{{- printf "%s-lpv-%s" .Values.services.mongodb.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-databasemongodb.mountPoint" -}}
{{- printf "%s/%s/%s/mongodb/db" .Values.services.mongodb.storage.mountPoint  .Values.services.mongodb.stackName .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-databasemongodb.configMountPoint" -}}
{{- printf "%s/%s/%s/mongodb/config-db" .Values.services.mongodb.storage.mountPoint .Values.services.mongodb.stackName .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "aangine-databasemongodb.labels" -}}
helm.sh/chart: {{ include "aangine-databasemongodb.chart" . }}
{{ include "aangine-databasemongodb.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
stack: {{ printf "%s-%s" .Values.services.mongodb.stackPrefix .Values.services.mongodb.stackName }}
tier: {{ .Values.services.mongodb.stackName }}
app: {{ .Values.services.mongodb.applicationName }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "aangine-databasemongodb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aangine-databasemongodb.name" . }}
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
app.kubernetes.io/component: {{ .Values.services.mongodb.applicationName }}
app.kubernetes.io/name: {{ .Values.services.mongodb.hostname }}
{{- end -}}


{{/*
Create the alternative data volume
*/}}
{{- define "aangine-databasemongodb.alternativeDataFolder" -}}
    {{ printf "%s/%s/%s" .Values.services.mongodb.storage.hostDataBaseFolder .Release.Namespace .Values.services.mongodb.applicationName }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "aangine-databasemongodb.serviceAccountName" -}}
  {{- printf "%s-%s-service-account" .Release.Namespace .Values.services.subdomain -}}
{{- end -}}
