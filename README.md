# Presentación del Proyecto: Pipeline CI/CD, Despliegue Avanzado y Buenas Prácticas

¡Bienvenidos a la presentación de nuestro proyecto! Este repositorio contiene la evolución de la aplicación **Inventario App** desde una simple aplicación local hacia un entorno robusto, automatizado y desplegado en Kubernetes siguiendo las mejores prácticas de la industria (CI/CD, estrategias de despliegue avanzadas y métricas DORA).

A continuación, explicamos paso a paso lo que hace nuestro proyecto en respuesta a los requerimientos planteados en las instrucciones.

---

## 🚀 1. Contenerización Segura y Eficiente (Docker Multi-stage)
Para asegurar que nuestra aplicación se despliega de manera confiable, implementamos un `Dockerfile` con enfoque **multi-stage**:
- **Etapa de Construcción (Builder):** Instalamos dependencias y ejecutamos los tests (`npm test`). **Si las pruebas fallan, la construcción de la imagen se detiene**, previniendo el empaquetado de código defectuoso.
- **Etapa de Producción:** Copiamos únicamente las dependencias de producción y los archivos esenciales (`server.js`, `db.js` y `public/`). Esto resulta en una imagen final sumamente ligera y segura, reduciendo la superficie de ataque.

## ⚙️ 2. Integración y Entrega Continua (GitHub Actions)
Automatizamos nuestro flujo de trabajo mediante un pipeline en `.github/workflows/ci-cd.yml` basado en el principio **fail-fast**:
- **Job `build-test`:** Se encarga de verificar el código ejecutando las pruebas.
- **Job `build-push`:** Solo se ejecuta si las pruebas son exitosas.
- **🔒 Escaneo de Seguridad (Componente Adicional 2):** Antes de publicar, utilizamos **Trivy** para escanear la imagen Docker. Si se detectan vulnerabilidades de infraestructura o librerías con severidad `CRITICAL`, el pipeline falla automáticamente.
- **Publicación:** Finalmente, la imagen es etiquetada (con el hash del commit y la etiqueta `latest`) y subida al GitHub Container Registry (`ghcr.io`).

## 🚢 3. Despliegue en Kubernetes (Rolling Update)
Desplegamos nuestra aplicación en un clúster de Kubernetes garantizando alta disponibilidad:
- Configuramos un `Deployment` base con 2 réplicas y una estrategia **RollingUpdate** (`maxUnavailable: 1`, `maxSurge: 1`), permitiendo actualizaciones graduales sin tiempo de inactividad para el usuario.
- **🛡️ Manejo de Secretos (Componente Adicional 1):** Protegimos nuestras credenciales (ej. `API_KEY`) utilizando un Secret de Kubernetes inyectado a través de `secretKeyRef` como variable de entorno, evitando por completo que datos sensibles terminen en el código fuente versionado.
- **⏳ Readiness y Arranque Lento (Componente Adicional 3):** Simulamos el comportamiento de una aplicación pesada (por ejemplo, una que demora en conectar a una base de datos) introduciendo un retardo en el arranque mediante la variable de entorno `STARTUP_DELAY_SECONDS="30"`. Ajustamos nuestra `readinessProbe` (aumentando su `failureThreshold`) para que Kubernetes tolere esta demora sin matar el Pod prematuramente, mientras que la `livenessProbe` asegura el monitoreo continuo de su estado de salud.

## 🚦 4. Estrategia de Despliegue Avanzado: Blue-Green
Para minimizar al máximo los riesgos al lanzar nuevas versiones frente a usuarios reales, implementamos una estrategia de despliegue **Blue-Green** utilizando los recursos nativos de Kubernetes.
- **Implementación:** Creamos dos Deployments independientes (Blue y Green) en el directorio `k8s/blue-green/`. Cada uno representa una versión o configuración diferente.
- **Corte de Tráfico Instantáneo:** Un único Service actúa como enrutador del tráfico. Al cambiar el `selector` de dicho Service (por ejemplo, de `color: blue` a `color: green`), logramos desviar el 100% del tráfico de los usuarios a la nueva versión de manera **instantánea**, facilitando un rollback inmediato si algo sale mal.

## 💾 5. Reflexión sobre la Persistencia de Datos
Un hallazgo clave durante nuestro desarrollo y despliegue inicial fue observar qué ocurre al eliminar o recrear un Pod. Dado que nuestra aplicación almacena su catálogo en un archivo JSON local (`data/products.json`) directamente dentro del contenedor, **los datos y cambios generados se pierden permanentemente cada vez que se recrea el Pod**. 
Esto evidencia y refuerza la necesidad en la vida real de utilizar bases de datos externas o la integración de Volúmenes Persistentes (Persistent Volumes) en Kubernetes para persistir el estado.

---

## 🛠️ Tutorial Paso a Paso: Levantando el Entorno desde Cero

Esta sección está diseñada como una guía práctica para demostrar el funcionamiento de todo nuestro ecosistema, ideal para presentaciones en vivo.

### Requisitos Previos
Asegúrate de tener instalados: `Node.js`, `Docker`, `Minikube` y `kubectl`.

### Paso 1: Ejecución y Pruebas Locales
Primero, demostremos que el código fuente funciona correctamente antes de empaquetarlo.

```bash
# Instalar dependencias
npm ci

# Ejecutar las pruebas unitarias (El paso clave de nuestro CI)
npm test

# Levantar la aplicación localmente
npm start
```
*Abre `http://localhost:3000` en tu navegador. Si creas un producto, cierras el servidor (`Ctrl+C`) y lo vuelves a iniciar, verás que el producto sigue ahí. Esto es porque los datos se guardan en el archivo local `data/products.json`.*

### Paso 2: Empaquetado con Docker (Multi-stage)
Ahora vamos a construir la imagen de Docker, demostrando nuestra optimización:

```bash
docker build -t inventario-app:local .
```
*Si observas los logs de construcción, verás que dentro de Docker se vuelve a ejecutar `npm test`. Si fallara, la imagen no se crearía.*

### Paso 3: Pipeline CI/CD (GitHub Actions)
En nuestro repositorio de GitHub, cualquier `push` a la rama `main` dispara automáticamente nuestro pipeline:
1. Pasa las pruebas.
2. Escanea vulnerabilidades críticas con **Trivy** (Componente 2).
3. Publica la imagen en `ghcr.io`.
*(Para demostrar esto en tu presentación, basta con mostrar la pestaña "Actions" del repositorio en GitHub con el check en verde).*

### Paso 4: Preparando Kubernetes y Secretos
Inicia tu clúster local:
```bash
minikube start
```
Antes de cualquier despliegue, inyectaremos de forma segura nuestras credenciales (**Componente 1**):
```bash
kubectl create secret generic api-secret --from-literal=API_KEY=mi_super_secreto
```

### Paso 5: Despliegue Base y Prueba de Arranque Lento
Vamos a desplegar la versión base. Aquí demostraremos el **Componente 3 (Arranque Lento)**:
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Observa cómo los Pods tardan 30 segundos en estar "READY"
kubectl get pods -w
```
Una vez que estén listos, expón el servicio y ábrelo en tu navegador:
```bash
minikube service inventario-service
```
*En el navegador, crea un producto. Luego, elimina el pod: `kubectl delete pod <nombre-del-pod>`. Cuando Kubernetes lo levante de nuevo automáticamente y refresques la página, verás que **el producto desapareció**. Esto demuestra el problema de usar almacenamiento efímero local en contenedores.*

### Paso 6: Demostración Estrella: Despliegue Blue-Green
Finalmente, demostraremos cómo actualizar nuestra aplicación sin interrumpir a los usuarios.

```bash
# 1. Desplegamos los entornos Blue (actual) y Green (nueva versión)
kubectl apply -f k8s/blue-green/deployment-blue.yaml
kubectl apply -f k8s/blue-green/deployment-green.yaml

# 2. Exponemos el tráfico apuntando a la versión Blue
kubectl apply -f k8s/blue-green/service.yaml

# 3. Obtenemos la URL del servicio (en otra terminal)
minikube service inventario-service-bg --url
```

Realiza una petición al servicio para confirmar que estás en el entorno Blue:
```bash
# (Reemplaza <URL> por lo que devolvió minikube, ej: http://192.168.49.2:30001)
curl <URL>/version
# Respuesta esperada: {"version":"v1","color":"blue",...}
```

**¡El Corte de Tráfico!**
Ahora simularemos el paso a producción de la nueva versión (Green), enviando el 100% del tráfico al instante modificando el selector del Service:
```bash
kubectl patch service inventario-service-bg -p '{"spec":{"selector":{"version":"green"}}}'
```

Vuelve a probar inmediatamente:
```bash
curl <URL>/version
# Respuesta instantánea: {"version":"v1","color":"green",...}
```
*¡Hemos actualizado nuestra aplicación a una nueva versión sin un solo segundo de inactividad!*

---
¡Gracias por acompañarnos en este recorrido hacia un ciclo de vida de software automatizado, seguro y resiliente!
