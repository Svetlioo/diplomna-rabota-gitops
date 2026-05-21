{{- define "fraud-detection.name" -}}
fraud-detection
{{- end -}}

{{- define "fraud-detection.fullname" -}}
{{ include "fraud-detection.name" . }}
{{- end -}}

{{- define "fraud-detection.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "fraud-detection.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "fraud-detection.labels" -}}
app.kubernetes.io/name: {{ include "fraud-detection.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: diploma
{{- end -}}

{{- define "fraud-detection.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fraud-detection.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "fraud-detection.image" -}}
{{- if and .Values.image.tag .Values.image.digest -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}@{{ .Values.image.digest }}
{{- else if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- end -}}
