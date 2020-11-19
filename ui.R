#
#
# Hector Mendia - 20000758 
# Estuardo Zapeta - 05244028
#
#

library(shiny)
library(shinythemes) # colores de la navbar
library(DBI) # odbc
library(ggplot2) # graficas


## conexion a la base de datos 
con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = "PostgreSQL ANSI",
                      Server   = "172.18.0.4",
                      Database = "postgres",
                      UID      = 'postgres',
                      PWD      = 'pass12345',
                      Port     = 5432)


# consulta para los kpi iniciales
totales <- dbGetQuery(conn= con, statement = "SELECT count(*) cantidad, sum(s.viewcount) vistas, sum(s.likecount) likes, sum(s.dislikecount) dislike, sum(s.commentcount) comentarios  from stats s")

# formato kpis
videos <- format(as.numeric(totales[1,1]), nsmall=0, big.mark=",")
vistas <- format(as.numeric(totales[1,2]), nsmall=0, big.mark=",")
likes <- format(as.numeric(totales[1,3]), nsmall=0, big.mark=",")
dislikes <- format(as.numeric(totales[1,4]), nsmall=0, big.mark=",")
comentarios <- format(as.numeric(totales[1,5]), nsmall=0, big.mark=",")


shinyUI(navbarPage(title = "Academatica Dashboard",
                   theme = shinytheme("cerulean"),
                   tabPanel(title="Resumen",
                            icon=icon("check"),
                            fluidRow(
                                column(4, 
                                       fluidRow(
                                           style = "background-color:#d9edf7;margin: 10px;",
                                           column(8, 
                                                  h3(videos),
                                                  h5("Total de videos")
                                                  ),
                                           column(3,tags$div(HTML('<i class="fa fa-youtube" style = "color:#0072B2; font-size: 5em;"></i>'))
                                           )
                                       )
                                ),
                                column(4, 
                                       fluidRow(
                                         style = "background-color:#d9edf7;margin: 10px;",
                                         column(8, 
                                                h3(vistas),
                                                h5("Total de vistas")
                                         ),
                                         column(3,tags$div(HTML('<i class="fa fa-desktop" style = "color:#0072B2; font-size: 5em;"></i>'))
                                         )
                                       )
                                ),
                                column(4,
                                       fluidRow(
                                         style = "background-color:#d9edf7;margin: 10px;",
                                         column(8, 
                                                h3(comentarios),
                                                h5("Total de comentarios")
                                         ),
                                         column(3,tags$div(HTML('<i class="fa fa-user-edit" style = "color:#0072B2; font-size: 5em;"></i>'))
                                         )
                                       )
                                       ),
                            ),
                            fluidRow(
                              column(6,
                                     plotOutput("grafica_top")
                                     ),
                              column(6,
                                     plotOutput("grafica_likes")
                              )
                              
                            ),
                            fluidRow(plotOutput("grafica_cantidad"))
                   ),
                   tabPanel(title= "Historico",
                            icon=icon("chart-line"),
                            fluidRow(
                                column(4, 
                                      offset = 2,
                                      selectInput("nivel",
                                                  "Nivel",
                                                  choices = c("Mes", "Trimestre","Año"))
                                ),
                                column(4,
                                      dateRangeInput("fechas", "Rango de Fechas",
                                                     start = "2015-01-01",
                                                     end = "2019-12-31",
                                                     min = "2006-10-07",
                                                     max = "2020-08-10",
                                                     format = "yyyy-mm-dd",
                                                     separator = " a ")
                                      
                                      
                                      )
                            ),
                            h3("Historico de Likes vs Dislikes"),
                            fluidRow(
                              column(11, plotOutput("historico_likes")),
                              column(1, fluidRow(h4("Likes", style = "color:blue"), h4("Dislike", style = "color:red")))
                            ),
                            h3("Word Cloud"),
                            fluidRow(
                              column(4,
                                     sliderInput("freq",
                                                 "Frecuencia:",
                                                 min = 1,  max = 50, value = 15),
                                     sliderInput("max",
                                                 "Cantidad de palabras:",
                                                 min = 1,  max = 300,  value = 100)
                              ),
                              column(8,
                                     plotOutput("plot_word")
                              )
                            )
                   )
                   
))
