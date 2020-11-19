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
* **dplyr**: Proporciona una forma bastante ágil de manejar los ficheros de datos de R.
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
**10. Vista general de la aplicación**

**10.1 Pestaña de Resumen**

En esta vista de alto nivel de la aplicación se observan algunos componentes del dashboard, los cuales fueron construidos utilizando bootstrap con la finalidad de darle un aspecto intuitivo.

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-3.png">

**10.1.1 Componentes sumarizados**

En esta sección se devuelve el resumen de tres variables:

* Videos
* Vistas
* Comentarios

Esta información se obtuvo de la estructura "stats" de la siguiente manera:

```sql
SELECT count(*) cantidad, sum(s.viewcount) vistas, sum(s.likecount) likes, sum(s.dislikecount) dislike, sum(s.commentcount) comentarios  from stats s
```

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-7.png">

**10.1.2 Gráfica de barras**

Este tipo de gráfico hace un énfasis especial en las variaciones de los datos a través de las vistas que cada video ha obtenido. Las categoría de videos aparece en el eje horizontal y los valores correspondientes a la cantidad de vistas en el eje vertical.

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-4.png">

**10.1.3 Gráfica de pie**

Este gráfico contiene una sola serie de datos que muestra los porcentajes de likes y dislikes.

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-5.png">

**10.1.4 Gráfica de línea**

Muestra las relaciones de los cambios en los datos en un período de tiempo. En este sentido hace un énfasis especial en las tendencias de los videos publicados por año.

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-6.png">

**10.2 Pestaña de Historico**

En esta parte se utilizó el concepto de reactividad, ya que la salida de los gráficos dependen de otros componentes.

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-8.png">

**10.2.1 Historico de likes vrs. dislikes**

En esta parte del aplicativo el gráfico reacciona dependiendo de los filtros que se seleccionen en la parte superior. Se puede establecer un periodo (bimestre, trimestre, semestre, etc.) o bien un rango de fecha.

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-9.png">

**10.2.2 Wordcloud**

La nube de palabras se diseñó con el objetivo de determinar la tendencia de los videos tomando de referencia el titulo del mismo, la reactividad del wordCloud esta en función de la frecuencia de las palabras o de la cantidad que se desea mostrar en pantalla. Los filtros de frecuencia y cantidad de palabras se encuentran definidos por componentes tipo slider que se muestran en la parte izquiera de la imagen.

<img src="https://raw.githubusercontent.com/estuardozapeta/Product-Development-Parcial-Fase1/main/grafica-10.png">