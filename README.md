## Parcial - Fase I

#### Integrantes

* 20000758 - Hector Alberto Heber Mendia Arriola
* 05244028 - Edwin Estuardo Zapeta Gómez

#### **Desarrollo**

A continuación se describen los pasos para el desarrollo del proyecto. Lo primero que se necesita son las imagenes para Rsutdio (entorno de desarrollo) y Postgres (base de datos donde se alojara la información).

**1. Comando para descargar imagen Rstudio**

```console
$ docker pull rocker/rstudio
```

**2. Comando para descargar imagen Postgres**

```console
$ docker pull postgres
```

Luego se debe iniciar el contenedor y conectarlo inmediatamente a una red.

**3. Iniciar contenedor**

```console
$ docker run -d --network my_test_network -p 3838:3838 -p 8787:8787 -e ADD=shiny -e PASSWORD=rstudio rocker/rstudio
```

* -d significa que un contenedor Docker se ejecuta en segundo plano en su terminal.
* -p 3838:3838 asigna el puerto 3838 en el contenedor al puerto 3838 en el host de Docker.
* -e sirve para establecer variables de entorno.

**4. Crear un volumen y luego configurar el contenedor**

```console
$ docker run -it -v C:\ProductDevelopment\parcial1:/data --network my_test_network --name db -e POSTGRES_PASSWORD=pass12345 -d postgres psql
```

El montaje se crea dentro del directorio / data del contenedor.

* -it -v muestra información detallada sobre uno o más volúmenes.

**5. Creación de tablas en Postgres**

En la imagen de Postgres levanatada se crearon las estructuras para cargar la información de los siguientes archivos .CSV:

* academatica_video_stats.csv
* academatica_videos.csv
* academatica_videos_metadata.csv

**5.1 DDL**

```sql
create table stats(
    id varchar(15),
    viewCount int,
    likeCount int,
    dislikeCount int,
    favoriteCount int,
    commentCount int
);

create table meta(
    video_id varchar(15),
    title varchar(100),
    description TEXT,
    iframe varchar(2048),
    link varchar(255)
);

create table videos(
    kind varchar(100),
    etag varchar(100),
    id varchar(100),
    videoId varchar(100),
    videoPublishedAt date
);
```

**6. Carga de CSV**

Para realizar el volcado de información (archivos .CSV) a las tablas creadas previamente se utilizó la función COPY de SQL.

```sql
COPY stats(id,viewCount,likeCount,dislikeCount,favoriteCount,commentCount)
FROM '/data/academatica_video_stats.csv'
DELIMITER ','
CSV HEADER;


COPY meta(video_id,title,description,iframe,link)
FROM '/data/academatica_videos_metadata.csv'
DELIMITER ','
CSV HEADER;


COPY videos(kind,etag,id,videoId,videoPublishedAt)
FROM '/data/academatica_videos.csv'
DELIMITER ','
CSV HEADER;
```

**7. Desarrollo de Shiny App**

**7.1 Librerias utilizadas**

```r
library(shiny)
library(ggplot2)
library(dplyr)
library(scales)
library(DBI)
```

* **shiny**: Paquete que facilita la creación de aplicaciones web interactivas directamente desde R.
* **ggplot2**: Crea visualizaciones de datos elegantes utilizando la gramática de gráficos.
* **dplyt**: Proporciona una forma bastante ágil de manejar los ficheros de datos de R.
* **scales**: Proporciona estética a los gráficos (etiquetas, ejes y leyendas).
* **DBI**: Definición de interfaz de base de datos para la comunicación entre R y los sistemas de gestión de bases de datos relacionales.

**8. Conexión a la base de datos desde R**

Los parametros que se configuran corresponden a las credenciales para conectarse a Postgres. Luego de establecer comunicación se seleccionaron los datos que servirían de insumo para los tableros de información.

```r
con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = "PostgreSQL ANSI",
                      Server   = "172.18.0.4",
                      Database = "postgres",
                      UID      = 'postgres',
                      PWD      = 'pass12345',
                      Port     = 5432)
```
**9. Vista general de la aplicación**

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-3.png">
