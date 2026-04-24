{{- define "team-worker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "team-worker.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Values.team .Values.environment | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "team-worker.labels" -}}
app.kubernetes.io/name: {{ include "team-worker.name" . }}
app.kubernetes.io/instance: {{ include "team-worker.fullname" . }}
app.kubernetes.io/managed-by: Helm
app.kubernetes.io/part-of: temporal-demo
demo.temporal.io/team: {{ .Values.team | quote }}
demo.temporal.io/environment: {{ .Values.environment | quote }}
{{- end -}}

