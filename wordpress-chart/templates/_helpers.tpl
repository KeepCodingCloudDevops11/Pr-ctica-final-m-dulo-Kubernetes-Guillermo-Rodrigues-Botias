{{/*
Genera el nombre completo del release.
Combina el nombre del release y el nombre del chart.
*/}}
{{- define "wordpress-chart.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Devuelve el nombre base del chart.
*/}}
{{- define "wordpress-chart.name" -}}
{{ .Chart.Name }}
{{- end -}}
