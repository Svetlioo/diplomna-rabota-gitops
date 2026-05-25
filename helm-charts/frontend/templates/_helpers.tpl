{{- define "frontend.name" -}}
frontend
{{- end -}}

{{- define "frontend.fullname" -}}
{{ include "frontend.name" . }}
{{- end -}}

{{- define "frontend.labels" -}}
app.kubernetes.io/name: {{ include "frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: diploma
{{- end -}}

{{- define "frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "frontend.image" -}}
{{- if and .Values.image.tag .Values.image.digest -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}@{{ .Values.image.digest }}
{{- else if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- end -}}
