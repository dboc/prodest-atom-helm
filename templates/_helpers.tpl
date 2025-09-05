{{/*
Helpers comuns para o Helm chart do Atom.
*/}}

{{/*
Expandir o nome do chart.
*/}}
{{- define "atom.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Criar um nome completo padrão para o chart.
*/}}
{{- define "atom.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Nome do chart e versão.
*/}}
{{- define "atom.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "atom.labels" -}}
helm.sh/chart: {{ include "atom.chart" . }}
{{ include "atom.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "atom.selectorLabels" -}}
app.kubernetes.io/name: {{ include "atom.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "atom.serviceAccountName" -}}
{{- if .Values.security.serviceAccount.create -}}
    {{ default (include "atom.fullname" .) .Values.security.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.security.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Nome do componente (usado para nomear recursos)
*/}}
{{- define "atom.component.fullname" -}}
{{- $componentName := index . 1 -}}
{{- printf "%s-%s" (include "atom.fullname" (index . 0)) $componentName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Labels do seletor para um componente específico
*/}}
{{- define "atom.component.selectorLabels" -}}
{{ include "atom.selectorLabels" (index . 0) }}
app.kubernetes.io/component: {{ index . 1 }}
{{- end -}}

{{/*
Labels para um componente específico
*/}}
{{- define "atom.component.labels" -}}
{{ include "atom.labels" (index . 0) }}
app.kubernetes.io/component: {{ index . 1 }}
{{- end -}}
