# Práctica-final-módulo-Kubernetes-Guillermo-Rodrigues-Botias
Práctica final módulo Kubernetes Guillermo Rodrigues Botias

## INDICE

* [*Primera parte*](#primera-parte) : Objetivos de la práctica y requisitos.
* [*Segunda parte*](#segunda-parte) : Creación de chart
* [*Tercera parte*](#tercera-parte) : Despliegue de aplicación
* [*Cuarta parte*](#cuarta-parte) :


## Primera Parte

En está práctica de kubernetes vamos a desplegar una aplicación con (Wordpress) y junto con una base de datos (MariaDB) utilizando Helm, garantizando que la aplicación sea accesible, resiliente, que los datos se almacenen de forma persistente y que sea escalable. 
Debemos cumplir los siguientes puntos:

* 1 Crearemos un gráfico de Helm: desarrollando un chart que incluya todos los recursos necesarios (deployments, HPA, probes, PVC, secrets, services, etc).
* 2 Configurar la persistencia de datos: Implementar un mecanismo de almacenamiento persistente para la base de datos (PVC para MariaDB).
* 3 Gestionar configuración sensible: Manejar credenciales y configuraciones sensibles usando recursos como Secrets, evitando exponer información crítica en el repositorio.
* 4 Asegurar Alta Disponibilidad (HA): Configurar réplicas mínimas en el deployment de WordPress para mantener la disponibilidad.
* 5 Escalar la aplicación automáticamente: Utilizar un Horizontal Pod Autoscaler (HPA) que ajuste las réplicas de WordPress cuando el uso de CPU supere el 70%.
* 6 Exponer la aplicación al exterior: Configurar servicios (NodePort o LoadBalancer) para que la aplicación sea accesible desde fuera del clúster.
* 7 Garantizar la resiliencia de la aplicación: Emplear mecanismos (liveness y readiness probes) que permitan detectar y reiniciar contenedores defectuosos.

**Requisitos previos**

Tenemos que asegurarnos de tener instalado lo siguiente, se tendrá que mirar la documentación ofifical ya que cambiara en función del sistema operativo:

* Docker Desktop, una vez instalado habilitamos la función de Kubernetes dentro de la configuración y lo reiniciamos.

* Minikube, comando para iniciarlo
 
```bash
Minikube start 
```
* Kubectl, herramienta de línea de comandos, comprobamos la version

```bash
kubectl version
```
* Helm, gestor de charts para kubernetes, vemos la version con
```bash
helm version
```
* Si es necesario actualizaremos los repositorios de bitnami con

  ```bash
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  ```

## Segunda Parte

Vamos a crear un chart de Helm incluyendo todos los recursos (Wordpress, MariaDB, Secrets, PVC, HPA, VAlues, _helpers, deployment, SVC)

La herramienta Helm nos falcilita el trabajo, nos dirigiremos a nuestra carpeta raiz de nuestro proyecto y una vez ahí, iniciamos el siguiente comando:

```bash
helm create wordpress-chart
```
lo que nos dará la siguiente [estructura inicial](https://github.com/KeepCodingCloudDevops11/Practica-final-modulo-Kubernetes-Guillermo-Rodrigues-Botias/blob/main/img/Creacion%20Estructura.png) 
* Borraremos y crearemos los archivos necesarios para finalmente dejar una [estructura final](https://github.com/KeepCodingCloudDevops11/Practica-final-modulo-Kubernetes-Guillermo-Rodrigues-Botias/blob/main/img/Estructura%20final.png)

* Creamos **values.yaml** para definir los parámetros personalizables

```bash
# values.yaml

# Parámetros globales
replicaCount: 2

image:
  wordpress:
    repository: wordpress
    tag: "php7.4-apache"   # Puedes usar la versión que desees
    pullPolicy: IfNotPresent
  mariadb:
    repository: mariadb
    tag: "10.5"
    pullPolicy: IfNotPresent

service:
  wordpress:
    type: LoadBalancer
    port: 80

mariadb:
  database: wordpress
  # Credenciales sensibles: las definimos aquí para usarlas en el Secret.
  username: gato
  password: cuadro
  persistence:
    enabled: true
    storageClass: "standard"  # Para Minikube suele ser "standard" o "default"
    size: 1Gi

hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70
```
* En el fichero **_helpers.tpl** definimos nombres y etiquetas

```bash
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
```

* Para las credenciales de la base de datos, creamos **db-secret.yaml**

```bash
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "wordpress-chart.fullname" . }}-db-secret
type: Opaque
data:
  # Se codifican en base64. Para 'gato' y 'cuadro':
  # echo -n 'gato' | base64  -> Z2F0bw==
  # echo -n 'cuadro' | base64 -> Y3VhZHJv
  username: {{ .Values.mariadb.username | b64enc | quote }}
  password: {{ .Values.mariadb.password | b64enc | quote }}
```

* La persistencia la haremos con **mariadb-pvc.yaml**

```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "wordpress-chart.fullname" . }}-mariadb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.mariadb.persistence.size }}
  storageClassName: {{ .Values.mariadb.persistence.storageClass }}
```

* Vamos ahora a crear el deployment de MariaDB con **mariadb-deployment.yaml**

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "wordpress-chart.fullname" . }}-mariadb
  labels:
    app: {{ include "wordpress-chart.name" . }}
    tier: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ include "wordpress-chart.name" . }}
      tier: mariadb
  template:
    metadata:
      labels:
        app: {{ include "wordpress-chart.name" . }}
        tier: mariadb
    spec:
      containers:
        - name: mariadb
          image: "{{ .Values.image.mariadb.repository }}:{{ .Values.image.mariadb.tag }}"
          imagePullPolicy: {{ .Values.image.mariadb.pullPolicy }}
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "wordpress-chart.fullname" . }}-db-secret
                  key: password
            - name: MYSQL_DATABASE
              value: "{{ .Values.mariadb.database }}"
            - name: MYSQL_USER
              valueFrom:
                secretKeyRef:
                  name: {{ include "wordpress-chart.fullname" . }}-db-secret
                  key: username
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "wordpress-chart.fullname" . }}-db-secret
                  key: password
          ports:
            - containerPort: 3306
          volumeMounts:
            - name: mariadb-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mariadb-storage
          persistentVolumeClaim:
            claimName: {{ include "wordpress-chart.fullname" . }}-mariadb-pvc
```

* El service de mariadb será **mariadb-service.yaml**

```bash
apiVersion: v1
kind: Service
metadata:
  name: {{ include "wordpress-chart.fullname" . }}-mariadb
spec:
  ports:
    - port: 3306
  selector:
    app: {{ include "wordpress-chart.name" . }}
    tier: mariadb
```

* Crearemos el deployment y service de Wordpress

Deployment **wordpress-deployment.yaml**

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "wordpress-chart.fullname" . }}-wordpress
  labels:
    app: {{ include "wordpress-chart.name" . }}
    tier: wordpress
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "wordpress-chart.name" . }}
      tier: wordpress
  template:
    metadata:
      labels:
        app: {{ include "wordpress-chart.name" . }}
        tier: wordpress
    spec:
      containers:
        - name: wordpress
          image: "{{ .Values.image.wordpress.repository }}:{{ .Values.image.wordpress.tag }}"
          ports:
            - containerPort: 80
          env:
            - name: WORDPRESS_DB_HOST
              value: "{{ include "wordpress-chart.fullname" . }}-mariadb:3306"
            - name: WORDPRESS_DB_USER
              valueFrom:
                secretKeyRef:
                  name: {{ include "wordpress-chart.fullname" . }}-db-secret
                  key: username
            - name: WORDPRESS_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "wordpress-chart.fullname" . }}-db-secret
                  key: password
            - name: WORDPRESS_DB_NAME
              value: "{{ .Values.mariadb.database }}"
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 5
```

El service **wordpress-service.yaml**

```bash
apiVersion: v1
kind: Service
metadata:
  name: {{ include "wordpress-chart.fullname" . }}-wordpress
  labels:
    app: {{ include "wordpress-chart.name" . }}
    tier: wordpress
spec:
  type: {{ .Values.service.wordpress.type }}
  ports:
    - name: http
      protocol: TCP
      port: {{ .Values.service.wordpress.port }}
      targetPort: 80
  selector:
    app: {{ include "wordpress-chart.name" . }}
    tier: wordpress
```

* Para conseguir el autoescalado horizontal creamos **wordpress-hpa.yaml**, pero para que funcione primero debemos habilitar el Metrics Server con

```bash
minikube addons enable metrics-server
```

```bash
{{- if .Values.hpa.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "wordpress-chart.fullname" . }}-wordpress
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "wordpress-chart.fullname" . }}-wordpress
  minReplicas: {{ .Values.hpa.minReplicas }}
  maxReplicas: {{ .Values.hpa.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.hpa.targetCPUUtilizationPercentage }}
{{- end }}
```

## Tercera Parte

Procedemos a desplegar la aplicación, nos ubicamos en el directorio raíz y ejecutamos

```bash
helm install mi-wordpress .
```
