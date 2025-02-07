# Práctica-final-módulo-Kubernetes-Guillermo-Rodrigues-Botias
Práctica final módulo Kubernetes Guillermo Rodrigues Botias

## INDICE

* [*Primera parte*](#primera-parte) : Objetivos de la práctica y requisitos.
* [*Segunda parte*](#segunda-parte) : Bases de datos MySQL
* [*Tercera parte*](#tercera-parte) : Pantilla de instancias; Grupo de Instancias
* [*Cuarta parte*](#cuarta-parte) : App Engine


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
