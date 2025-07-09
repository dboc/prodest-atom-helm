{{/*
Expand the name of the chart.
*/}}
{{- define "atom.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "atom.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "atom.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

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
{{- if .Values.serviceAccount.create }}
{{- default (include "atom.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name for MySQL.
*/}}
{{- define "atom.mysql.fullname" -}}
{{- printf "%s-%s" (include "atom.fullname" .) "mysql" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name for Memcached.
*/}}
{{- define "atom.memcached.fullname" -}}
{{- printf "%s-%s" (include "atom.fullname" .) "memcached" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name for Gearman.
*/}}
{{- define "atom.gearman.fullname" -}}
{{- printf "%s-%s" (include "atom.fullname" .) "gearman" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name for Nginx.
*/}}
{{- define "atom.nginx.fullname" -}}
{{- printf "%s-%s" (include "atom.fullname" .) "nginx" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name for AtoM Worker.
*/}}
{{- define "atom.worker.fullname" -}}
{{- printf "%s-%s" (include "atom.fullname" .) "worker" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create MySQL DSN
*/}}
{{- define "atom.mysql.dsn" -}}
mysql:host={{ include "atom.mysql.fullname" . }};port=3306;dbname={{ .Values.mysql.auth.database }};charset=utf8mb4
{{- end }}

{{/*
Create Elasticsearch URL
*/}}
{{- define "atom.elasticsearch.url" -}}
{{- printf "%s://%s:%s" .Values.atom.env.elasticsearchProtocol .Values.atom.env.elasticsearchHost .Values.atom.env.elasticsearchPort }}
{{- end }}

{{/*
Create route host
*/}}
{{- define "atom.route.host" -}}
{{- printf "%s.%s" .Values.nginx.route.host .Values.global.domain }}
{{- end }}

{{/*
Image name helper
*/}}
{{- define "atom.image" -}}
{{- $registry := .Values.global.imageRegistry -}}
{{- $repository := .Values.atom.image.repository -}}
{{- $tag := .Values.atom.image.tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Nginx image name helper
*/}}
{{- define "atom.nginx.image" -}}
{{- $registry := .Values.global.imageRegistry -}}
{{- $repository := .Values.nginx.image.repository -}}
{{- $tag := .Values.nginx.image.tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
MySQL image name helper
*/}}
{{- define "atom.mysql.image" -}}
{{- $registry := .Values.global.imageRegistry -}}
{{- $repository := .Values.mysql.image.repository -}}
{{- $tag := .Values.mysql.image.tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Memcached image name helper
*/}}
{{- define "atom.memcached.image" -}}
{{- $registry := .Values.global.imageRegistry -}}
{{- $repository := .Values.memcached.image.repository -}}
{{- $tag := .Values.memcached.image.tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Gearman image name helper
*/}}
{{- define "atom.gearman.image" -}}
{{- $registry := .Values.global.imageRegistry -}}
{{- $repository := .Values.gearman.image.repository -}}
{{- $tag := .Values.gearman.image.tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}
