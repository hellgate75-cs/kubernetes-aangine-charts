{{/* vim: set filetype=mustache: */}}
{{/*
Define the name of the components in the chart.
*/}}
{{- define "aangine-system-local-volume-provisioner.serviceAccountName" -}}
{{- printf "%s-lpv-%s-sa" .Values.services.local_volume_provisioner.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-system-local-volume-provisioner.clusterRoleName" -}}
{{- printf "%s-lpv-%s-cr" .Values.services.local_volume_provisioner.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-system-local-volume-provisioner.clusterRoleBindingName" -}}
{{- printf "%s-lpv-%s-crb" .Values.services.local_volume_provisioner.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-system-local-volume-provisioner.pathProvisionerName" -}}
{{- printf "%s-lpv-%s-prov" .Values.services.local_volume_provisioner.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-system-local-volume-provisioner.configMapName" -}}
{{- printf "%s-lpv-%s-cm" .Values.services.local_volume_provisioner.stackPrefix .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the definition of the general stack Kubernetes domain.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Kube-Dns default Kubernetes Domain name is composed by subdomain, namespace and a fixed suffix.
*/}}
{{- define "aangine-system-local-volume-provisioner.domainName" -}}
	{{- if (.Values.services.subdomain) -}}
		{{- printf "%s.%s.svc.cluster.local" .Values.services.subdomain .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- else -}}
		{{- printf "%s.svc.cluster.local" .Release.Namespace | trunc 63 | trimSuffix "-" -}}
	{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aangine-system-local-volume-provisioner.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "aangine-system-local-volume-provisioner.storagePath" -}}
{{- printf "%s/%s/%s" .Values.services.local_volume_provisioner.storage.hostBindingFolder .Values.services.local_volume_provisioner.stackPrefix .Release.Namespace -}}
{{- end -}}


{{/*
Common labels
*/}}
{{- define "aangine-system-local-volume-provisioner.labels" -}}
helm.sh/chart: {{ include "aangine-system-local-volume-provisioner.chart" . }}
{{ include "aangine-system-local-volume-provisioner.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
stack: {{ printf "%s-%s" .Values.services.local_volume_provisioner.stackPrefix .Values.services.local_volume_provisioner.stackName }}
tier: {{ .Values.services.local_volume_provisioner.stackName }}
scope: {{ .Values.services.local_volume_provisioner.applicationName }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "aangine-system-local-volume-provisioner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aangine-system-local-volume-provisioner.pathProvisionerName" . }}
{{- if $.Release.Name }}
app.kubernetes.io/instance: "{{ .Release.Name }}"
{{- end }}
{{- if $.Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.services.subdomain }}
app.kubernetes.io/domain: {{ .Values.services.subdomain }}
{{- end }}
app.kubernetes.io/namespace: {{ .Release.Namespace }}
app.kubernetes.io/component: {{ .Values.services.local_volume_provisioner.applicationName }}
{{- end -}}

