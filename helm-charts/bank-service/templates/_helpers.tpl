{{- define "bank-service.name" -}}
bank-service
{{- end -}}

{{- define "bank-service.fullname" -}}
{{ include "bank-service.name" . }}
{{- end -}}

{{- define "bank-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "bank-service.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "bank-service.labels" -}}
app.kubernetes.io/name: {{ include "bank-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: diploma
{{- end -}}

{{- define "bank-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bank-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "bank-service.image" -}}
{{- if and .Values.image.tag .Values.image.digest -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}@{{ .Values.image.digest }}
{{- else if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- end -}}
