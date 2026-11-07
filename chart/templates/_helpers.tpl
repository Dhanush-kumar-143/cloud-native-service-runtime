{{- define "cloud-native-service-runtime.labels" -}}
app.kubernetes.io/name: cloud-native-service-runtime
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
