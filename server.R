#
#
# Hector Mendia - 20000758 
# Estuardo Zapeta - 05244028
#
#

library(shiny)
library(ggplot2)
library(dplyr)
library(scales)
library(DBI)
library(tm)
library(wordcloud)
library(memoise)


con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = "PostgreSQL ANSI",
                      Server   = "172.18.0.4",
                      Database = "postgres",
                      UID      = 'postgres',
                      PWD      = 'pass12345',
                      Port     = 5432)

processNLP <- memoise(function(text) {
  
  corpus = Corpus(VectorSource(text))
  corpus = tm_map(corpus, content_transformer(tolower))
  corpus = tm_map(corpus, function(x) iconv(x, to='UTF-8', sub = "byte"))
  corpus = tm_map(corpus, removePunctuation)
  corpus = tm_map(corpus, removeNumbers)
  corpus = tm_map(corpus, removeWords,
                  c(stopwords("SMART"), "thy", "thou", "thee", "the", "and", "but"))
  
  dtm = TermDocumentMatrix(corpus,
                           control = list(minWordLength = 1))
  
  m = as.matrix(dtm)
  
  sort(rowSums(m), decreasing = TRUE)
})


shinyServer(function(input, output) {
    
  output$grafica_likes <- renderPlot({
    totales <- dbGetQuery(conn= con, statement = "SELECT sum(s.likecount) likes, sum(s.dislikecount) dislike,sum(s.likecount + s.dislikecount) total  from stats s")
    
    p1 <- totales[1,1]/(totales[1,3])
    p2 <- totales[1,2]/(totales[1,3])
    
    dfLikes <- data.frame(
      Tipo = c("Likes", "Dislike"),
      Cantidad = c(as.numeric(p1),as.numeric(p2))
    )
    
    
    bp<- ggplot(dfLikes, aes(x="", y=Cantidad, fill=Tipo))+
      ggtitle("Likes vs Dislikes") +
      geom_bar(stat="identity", width=1, color="white") + 
      coord_polar("y", start=0) + 
      theme_void() +
      #theme(legend.position="none") +
      geom_text(aes(y = Cantidad/2 + c(0, cumsum(Cantidad)[-length(Cantidad)]), 
                    label = percent(Cantidad/100)), size=5)
      #geom_text(aes(y = ypos, label = Tipo), color = "white", size=6) +
      #scale_fill_brewer(palette="Set1")
      
    bp
  })
  
  output$grafica_top <- renderPlot({
    totales <- dbGetQuery(conn= con, statement = "SELECT s.viewcount vistas, s.id from stats s,meta m where s.id=m.video_id order by 1 desc limit 5")
    
    
    df <- data.frame(id=as.list(totales["id"]),
                     vistas=as.list(totales["vistas"]/1000))
    
    bp <- ggplot(data=df, aes(x=id, y=vistas)) +
      ggtitle("Top Videos Vistos (miles)") +
      geom_bar(stat="identity", fill="steelblue")
    bp
    
  })
  
  output$grafica_cantidad <- renderPlot({
    totales <- dbGetQuery(conn= con, statement = "select extract(year from videoPublishedAt) || '' as anyo, count(*) total from videos group by 1 order by 1")
    
    
    df <- data.frame(anyo=as.list(totales["anyo"]),
                     total=lapply(as.list(totales["total"]),as.integer))
    
    
    
    bp <- ggplot(data=df, aes(x=anyo, y=total, group = 1)) +
      ggtitle("Videos publicados por año") +
      geom_line(color="steelblue") +
      xlab('Año')
      geom_point()
      
      #geom_bar(stat="identity")
    bp
    
  })
  
  
  #output$click_data <- renderPrint({
  #  clk_msg <- NULL
  #  if (!is.null(input$clk$x)){
  #    #browser()
  #    #print(input$clk$x)    
  #    clk_msg <- paste0("click coordenada x= ", round(input$clk$x,2),
  #                      " click coordenada y= ", round(input$clk$y,2))
  #    #print(clk_msg)
  #  }
  #  clk_msg
  #  #cat(clk_msg, dclk_msg, mhover_msg, mbrush, sep = "\n")
  #  
  #})
  
  

  hist_likes <- reactive({
     
    query <- ""
    if (input$nivel=="Mes"){
      query <- paste("select extract(year from videoPublishedAt) || '-' || extract(month from videoPublishedAt) || '' as fecha, sum(s.likecount) likes, sum(s.dislikecount) dislike, sum(s.viewcount) vistas 
        from stats s, videos v where s.id=videoId and videoPublishedAt >= '",input$fechas[1] ,"00:00:00' and videoPublishedAt<='",input$fechas[2] ," 23:59'
        group by 1 order by 1")
      
    }else if (input$nivel=="Trimestre"){
      query <- paste("select extract(year from videoPublishedAt) || '-' || extract(QUARTER from videoPublishedAt) || '' as fecha, sum(s.likecount) likes, sum(s.dislikecount) dislike, sum(s.viewcount) vistas 
        from stats s, videos v where s.id=videoId and videoPublishedAt >= '",input$fechas[1] ,"00:00:00' and videoPublishedAt<='",input$fechas[2] ," 23:59'
        group by 1 order by 1")
      
    }else{
      query <- paste("select extract(year from videoPublishedAt) || '' as fecha, sum(s.likecount) likes, sum(s.dislikecount) dislike , sum(s.viewcount) vistas 
        from stats s, videos v where s.id=videoId and videoPublishedAt >= '",input$fechas[1] ,"00:00:00' and videoPublishedAt<='",input$fechas[2] ," 23:59'
        group by 1 order by 1")
      
    }
    
    #query <- paste("select extract(year from videoPublishedAt) || '' as anyo, sum(s.likecount) likes, sum(s.dislikecount) dislike 
    #from stats s, videos v where s.id=videoId and videoPublishedAt >= '",input$fechas[1] ,"00:00:00' and videoPublishedAt<='",input$fechas[2] ," 23:59'
    #group by 1 order by 1")
    
    totales <- dbGetQuery(conn= con, statement = query)
    
    
    df <- data.frame(fecha=as.list(totales["fecha"]),
                     vistas=lapply(as.list(totales["vistas"]),as.integer),
                     likes=lapply(as.list(totales["likes"]),as.integer),
                     dislike=lapply(as.list(totales["dislike"]),as.integer))
    
    #print(df)
    #bp <- ggplot(data=df, aes(x=likes, y=total, group = 1)) +
    #  ggtitle("Historico de likes & dislikes") +
    #  geom_line(color="steelblue") +
    #  geom_point()
    
    #bp <- 
    
    #  geom_line(aes(y = dislike, colour = "var1"))
    
    #geom_bar(stat="identity")
    coeff <- 1000
    
    bp <- ggplot(df) + 
      geom_line(aes(x=fecha,y=dislike, group=1),color='red') +
      geom_point(aes(x=fecha,y=dislike)) + 
      geom_line(aes(x=fecha,y=likes, group=2),color='blue') +
      geom_point(aes(x=fecha,y=likes)) + 
      
      #geom_line(aes(x=fecha,y=vistas/coeff, group=3),color='green') +
      
      #ggtitle("Historico de likes & dislikes") +
      ylab('Cantidad')+
      xlab('Fecha')
      #scale_y_continuous(
      #  # Features of the first axis
      #  name = "Likes & Dislike",
      #  
      #  # Add a second axis and specify its features
      #  sec.axis = sec_axis(~.*coeff, name="Vistas")
      #)
    
      #geom_point()
    bp
    
  })
  
  
  output$historico_likes <- renderPlot(
    hist_likes()
  )
  
  terms <- reactive({
    #input$update
    query <- paste("select title from meta m, videos v where m.video_id=videoId 
         and videoPublishedAt >= '",input$fechas[1] ,"00:00:00' and videoPublishedAt<='",input$fechas[2] ," 23:59' ")   
    
    totales <- dbGetQuery(conn= con, statement = query)
    print(totales)
    
    isolate({
      withProgress({
        #mydata <- read.csv("academatica_videos_metadata.csv", header = TRUE)
        
        df <- data.frame(as.list(totales["title"]))
        processNLP(df$title)
      })
    })
  })
  wordcloud_rep <- repeatable(wordcloud)
  
  output$plot_word <- renderPlot({
    v <- terms()
    wordcloud_rep(names(v), v, scale=c(4,0.5),
                  min.freq = input$freq, max.words=input$max,
                  colors=brewer.pal(8, "Dark2"))
  })
  
})
