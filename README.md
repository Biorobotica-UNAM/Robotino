# Robotino

Este repositorio concentra la infraestructura necesaria para la construcción, despliegue y ejecución del entorno de hardware de **JUSTINA** sobre **ROS 2 Jazzy**, con énfasis en la operación del robot móvil **Robotino**. Su objetivo es ofrecer un flujo de trabajo claro y reproducible para generar la imagen Docker del sistema, transferirla al robot y poner en marcha los nodos de hardware correspondientes.

## Objetivo

El procedimiento descrito en este documento permite:

- construir la imagen Docker del entorno de hardware;
- exportarla en un formato portable;
- transferirla al robot Robotino;
- cargar y ejecutar el contenedor en el robot;
- lanzar la infraestructura ROS 2 asociada al hardware;
- configurar la comunicación DDS desde cualquier computadora de trabajo sin necesidad de registrar su IP en el robot.

## Estructura relevante

Los archivos principales involucrados en este flujo son los siguientes:

- `docker/export_image.sh`: construye la imagen Docker y genera el archivo comprimido para su transferencia.
- `docker/run_robotino.sh`: ejecuta el contenedor con la configuración necesaria para acceder al hardware del robot.
- `docker/config/cyclonedds.xml`: configuración DDS embebida en la imagen del robot. Anuncia su presencia a toda la subred mediante broadcast.
- `src/justina_hardware/launch/hardware.launch.xml`: launch principal para el arranque de los nodos de hardware.

## Procedimiento de despliegue

### 0. Actualización opcional del workspace

Si se requiere trabajar con la versión más reciente de los paquetes contenidos en `src`, actualice previamente los repositorios correspondientes.

### 1. Construcción de la imagen Docker

Ubique su terminal dentro del directorio `docker`:

```bash
cd ~/Robotino/docker
```

Si no tiene Docker instalado:

```bash
sudo apt install docker.io
```

Construya y exporte la imagen con:

```bash
sudo ./export_image.sh
```

Este script genera la imagen `robotino:jazzy` y produce el archivo `robotino_jazzy.tar.gz` en la raíz del proyecto.

### 2. Transferencia de la imagen al robot

Con el robot encendido y conectado a la misma red, transfiera el archivo al equipo Robotino:

```bash
scp ~/Robotino/robotino_jazzy.tar.gz robotino@robotino:~/
```

### 3. Acceso remoto al robot

Establezca una sesión SSH con el robot:

```bash
ssh robotino@robotino
```

## Ejecución en Robotino

Las instrucciones de esta sección se realizan directamente dentro del robot.

### 4. Carga de la imagen Docker

Importe la imagen transferida:

```bash
docker load -i robotino_jazzy.tar.gz
```

### 5. Ejecución del contenedor

Una vez cargada la imagen, inicie el contenedor con:

```bash
docker run --rm -it \
  --network host \
  --ipc host \
  --pid host \
  --privileged \
  -e RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
  -e ROS_DOMAIN_ID=0 \
  -v /dev:/dev \
  -v /run/udev:/run/udev:ro \
  robotino:jazzy
```

Si se prefiere, puede utilizarse el script `docker/run_robotino.sh`, el cual contiene una variante del comando de arranque del contenedor.

### 6. Lanzamiento del hardware

Dentro del contenedor, ejecute el launch principal del hardware:

```bash
ros2 launch justina_hardware hardware.launch.xml
```

## Configuración desde la computadora de trabajo

Una vez que el contenedor se encuentre en ejecución en Robotino, regrese a su computadora y configure el entorno DDS. **No es necesario registrar la IP de su máquina en el robot** — Robotino anuncia su presencia a toda la subred automáticamente.

### 7. Requisitos

Si no tiene el middleware de Cyclone DDS instalado:

```bash
sudo apt install ros-jazzy-rmw-cyclonedds-cpp
```

### 8. Archivo de configuración DDS

El archivo debe colocarse en `/etc/cyclonedds/cyclonedds.xml`. Como es una ruta del sistema, la creación requiere `sudo`:

```bash
sudo mkdir -p /etc/cyclonedds
sudo nano /etc/cyclonedds/cyclonedds.xml
```

Pegue el siguiente contenido:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<CycloneDDS xmlns="https://cdds.io/config">
  <Domain id="any">
    <General>
      <Interfaces>
        <NetworkInterface name="YOUR_INTERFACE"/>
      </Interfaces>
      <AllowMulticast>false</AllowMulticast>
      <MaxMessageSize>65500B</MaxMessageSize>
    </General>
    <Discovery>
      <ParticipantIndex>auto</ParticipantIndex>
      <MaxAutoParticipantIndex>100</MaxAutoParticipantIndex>
      <Peers>
        <Peer address="172.27.1.1"/>
        <Peer address="172.27.1.255"/>
      </Peers>
    </Discovery>
  </Domain>
</CycloneDDS>
```

Sustituya `YOUR_INTERFACE` por el nombre de su interfaz de red conectada a Robotino. Para identificarla:

```bash
ip link show
# Ejemplos comunes: eno1, eno2, eth0, enp3s0
```

> El peer `172.27.1.255` es la dirección de broadcast de la subred `/24`. Permite que Robotino sea descubierto por cualquier máquina en la red sin necesidad de registrar su IP en el robot.

### 9. Activación del entorno

Utilice el alias:

alias justina_on='export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp; export CYCLONEDDS_URI=file:///etc/cyclonedds/cyclonedds.xml; export ROS_DOMAIN_ID=0; export ROS_LOCALHOST_ONLY=0'

```bash
justina_on
```

### 10. Verificación

```bash
ros2 daemon stop && ros2 daemon start
ros2 topic list
```

## Consideraciones importantes

- La configuración DDS del robot (`docker/config/cyclonedds.xml`) usa broadcast de subred. Cualquier máquina en la red `172.27.1.0/24` con el archivo `/etc/cyclonedds/cyclonedds.xml` del paso 8 puede ver los tópicos de Robotino sin modificar nada dentro del robot.
- Asegúrese de que la computadora de trabajo y Robotino se encuentren dentro de la misma red y con conectividad funcional (`ping 172.27.1.1`).
- El uso de `sudo` durante la construcción de la imagen puede ser necesario dependiendo de la configuración local de Docker.

## Resumen operativo

```
[Computadora] ./export_image.sh → robotino_jazzy.tar.gz
     │
     └─ scp → [Robotino] docker load → docker run → ros2 launch hardware.launch.xml
                                                              │
[Computadora] justina_on → ros2 topic list ←─────────────────┘
```

El flujo consiste en construir la imagen del entorno de hardware, transferirla al robot, ejecutarla dentro de Robotino y habilitar la comunicación DDS desde la computadora de trabajo. Siguiendo esta secuencia, cualquier miembro del equipo puede conectarse a Robotino configurando únicamente el nombre de su interfaz de red local.
