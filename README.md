# Justina Hardware

Este repositorio concentra la infraestructura necesaria para la construccion, despliegue y ejecucion del entorno de hardware de **JUSTINA** sobre **ROS 2 Jazzy**, con enfasis en la operacion del robot movil **Robotino**. Su objetivo es ofrecer un flujo de trabajo claro y reproducible para generar la imagen Docker del sistema, transferirla al robot y poner en marcha los nodos de hardware correspondientes.

## Objetivo

El procedimiento descrito en este documento permite:

- construir la imagen Docker del entorno de hardware;
- exportarla en un formato portable;
- transferirla al robot Robotino;
- cargar y ejecutar el contenedor en el robot;
- lanzar la infraestructura ROS 2 asociada al hardware;
- configurar la comunicacion DDS desde la computadora de trabajo.

## Estructura relevante

Los archivos principales involucrados en este flujo son los siguientes:

- `docker/export_image.sh`: construye la imagen Docker y genera el archivo comprimido para su transferencia.
- `docker/run_robotino.sh`: ejecuta el contenedor con la configuracion necesaria para acceder al hardware del robot.
- `docker/config/cyclonedds.xml`: archivo de configuracion de DDS que debe revisarse antes de operar desde la computadora.
- `src/justina_hardware/launch/hardware.launch.xml`: launch principal para el arranque de los nodos de hardware.

## Procedimiento de despliegue

### 0. Actualizacion opcional del workspace

Si se requiere trabajar con la version mas reciente de los paquetes contenidos en `src`, actualice previamente los repositorios correspondientes.

### 1. Construccion de la imagen Docker

Ubique su terminal dentro del directorio `docker`:

```bash
cd ~/justina_hardware/docker
```

Si no tienes docker, instálalo con:

sudo apt install docker.io

Construya y exporte la imagen con:

```bash
sudo ./export_image.sh
```

Este script genera la imagen `justina_hardware:jazzy` y produce el archivo:

```bash
justina_hardware_jazzy.tar.gz
```

en la raiz del proyecto.

### 2. Transferencia de la imagen al robot

Con el robot encendido y conectado a la misma red, transfiera el archivo al equipo Robotino:

```bash
scp ~/justina_hardware/justina_hardware_jazzy.tar.gz robotino@robotino:~/
```

### 3. Acceso remoto al robot

Establezca una sesion SSH con el robot:

```bash
ssh robotino@robotino
```

## Ejecucion en Robotino

Las instrucciones de esta seccion se realizan directamente dentro del robot.

### 4. Carga de la imagen Docker

Importe la imagen transferida:

```bash
docker load -i justina_hardware_jazzy.tar.gz
```

### 5. Ejecucion del contenedor

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
  justina_hardware:jazzy
```

Si se prefiere, puede utilizarse como referencia el script `docker/run_robotino.sh`, el cual contiene una variante del comando de arranque del contenedor.

### 6. Lanzamiento del hardware

Dentro del contenedor, ejecute el launch principal del hardware:

```bash
ros2 launch justina_hardware hardware.launch.xml
```

## Configuracion desde la computadora de trabajo

Una vez que el contenedor se encuentre en ejecucion en Robotino, regrese a la computadora de trabajo y configure el entorno DDS correspondiente.

### 7. Activacion de la configuracion local

Ejecute el alias:

```bash
justina_on
```

Este paso prepara los archivos de configuracion necesarios para la comunicacion mediante DDS.

## Consideraciones importantes

- Verifique que la direccion IP definida en `/cyclonedds.xml` corresponda a la de su computadora.
- Asegurese de que la computadora de trabajo y Robotino se encuentren dentro de la misma red y con conectividad funcional.
- El uso de `sudo` durante la construccion de la imagen puede ser necesario dependiendo de la configuracion local de Docker.

## Resumen operativo

En terminos generales, el flujo de trabajo consiste en construir la imagen del entorno de hardware, transferirla al robot, ejecutarla dentro de Robotino y finalmente habilitar la comunicacion DDS desde la computadora de trabajo. Siguiendo esta secuencia, es posible desplegar de manera ordenada y reproducible la infraestructura base de hardware de JUSTINA.
