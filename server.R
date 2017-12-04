library(shiny)
library(ggplot2)
library(DT)
library(data.table)
library(RMariaDB)
library(RMySQL)

function(input, output, session){
  options(shiny.sanitize.errors = TRUE)
  cols_sequencer <- c("hiseq_umc01" = "#009E73", "nextseq_umc01" = "#0072B2", "nextseq_umc02" = "#D55E00", "novaseq_umc01" = "#D4AC0D")
  cols_lanes <- c("1" = "darkred", "2" = "darkgoldenrod2", "3" = "navyblue", "4" = "cyan3")
  shape_sequencer <- c("hiseq_umc01" = 15, "nextseq_umc01" = 19, "nextseq_umc02" = 18, "novaseq_umc01" = 17)
  
  query_sample_seq <- function(x, y, date_min, date_max){
    con <- dbConnect(RMariaDB::MariaDB(), group="trendngs")
    query = sprintf("SELECT %s, %s, Sequencer, asDate FROM Run JOIN Sample_Sequencer ON Run.Run_ID = Sample_Sequencer.Run_ID AND (Run.asDate BETWEEN %s AND %s)", x, y, date_min, date_max)
    response <- dbSendQuery(con, query)
    results <- dbFetch(response,n=-1)
    dbClearResult(response)
    dbDisconnect(con)
    return(results)
  }
  query_run_lane <- function(x, y, date_min, date_max){
    con <- dbConnect(RMariaDB::MariaDB(), group="trendngs")
    query <- sprintf("SELECT %s, %s, Sequencer, Lane FROM Run JOIN Run_per_Lane ON Run.Run_ID = Run_per_Lane.Run_ID AND (Run.asDate BETWEEN %s AND %s)", x, y, date_min, date_max)
    response <- dbSendQuery(con, query)
    results <- dbFetch(response, n=-1)
    dbClearResult(response)
    dbDisconnect(con)
    return(results)
  }
  query_sample_proc <- function(x, y, date_min, date_max){
    con <- dbConnect(RMariaDB::MariaDB(), group="trendngs")
    query <- sprintf("SELECT %s, %s, Sequencer FROM Run JOIN Sample_Processed ON Run.Run_ID = Sample_Processed.Run_ID AND (Run.asDate BETWEEN %s AND %s)", x, y, date_min, date_max)
    response <- dbSendQuery(con, query)
    results <- dbFetch(response, n=-1)
    dbClearResult(response)
    dbDisconnect(con)
    return(results)
  }
  query_run <- function(x,y,date_min,date_max){
    con <- dbConnect(RMariaDB::MariaDB(), group="trendngs")
    query <- sprintf("SELECT %s, %s, Sequencer FROM Run WHERE asDate BETWEEN %s AND %s", x, y, date_min, date_max)
    response <- dbSendQuery(con, query)
    results <- dbFetch(response, n=-1)
    dbClearResult(response)
    dbDisconnect(con)
    return(results)
  }
  query_math <- function(a,b,x,y,date_min,date_max){
    con <- dbConnect(RMariaDB::MariaDB(), group="trendngs")
    query = sprintf("SELECT %s, (%s / %s)*100 AS '%s', Sequencer FROM Run JOIN Sample_Processed ON Run.Run_ID = Sample_Processed.Run_ID AND (Run.asDate BETWEEN %s AND %s)", x,a,b,y,date_min,date_max )
    response <- dbSendQuery(con, query)
    results <- dbFetch(response, n=-1)
    dbClearResult(response)
    dbDisconnect(con)
    # print(results)
    return(results)
  }
  
  query_run_table <- function(columns){
    con <- dbConnect(RMariaDB::MariaDB(), group="trendngs")
    query <- sprintf("SELECT Run, %s, Sequencer FROM Run JOIN Sample_Sequencer ON Run.Run_ID = Sample_Sequencer.Run_ID",columns)
    response <- dbSendQuery(con, query)
    results <- dbFetch(response, n=-1)
    dbClearResult(response)
    dbDisconnect(con)
    return(results)
  }
  query_lane_table <- function(columns){
    con <- dbConnect(RMariaDB::MariaDB(), group="trendngs")
    query <- sprintf("SELECT Run, %s, Sequencer FROM Run JOIN Run_per_Lane ON Run.Run_ID = Run_per_Lane.Run_ID",columns)
    response <- dbSendQuery(con, query)
    results <- dbFetch(response, n=-1)
    dbClearResult(response)
    dbDisconnect(con)
    return(results)
  }
  query_processed_table <- function(columns){
    con <- dbConnect(RMariaDB::MariaDB(), group="trendngs")
    query <- sprintf("SELECT Run.Run, %s, Sequencer FROM Run JOIN Sample_Processed ON Run.Run_ID = Sample_Processed.Run_ID", columns)
    response <- dbSendQuery(con, query)
    results <- dbFetch(response, n=-1)
    dbClearResult(response)
    dbDisconnect(con)
    return(results)
  }
  
  output$Proc_columns <- renderUI({
    con <- dbConnect(RMySQL::MySQL(), group="trendngs")
    res <- suppressWarnings(dbSendQuery(con, "SELECT Run.Run, Run.Sequencer, Sample_Processed.* FROM Run JOIN Sample_Processed ON Run.Run_ID = Sample_Processed.Run_ID LIMIT 1"))
    columns <- dbListFields(res)
    dbClearResult(res)
    dbDisconnect(con)
    kolomn <- c()
    for(col in columns){
      if(!grepl("ID", col)){
        kolomn <- c(kolomn, col)
      }
    }
    checkboxGroupInput("columns_processed", "Columns", kolomn,selected = kolomn[1:length(kolomn)])
  })
  output$Samp_columns <- renderUI({
    con <- dbConnect(RMySQL::MySQL(), group="trendngs")
    res <- suppressWarnings(dbSendQuery(con, "SELECT Run.Run, Run.Sequencer, Sample_Sequencer.* FROM Run JOIN Sample_Sequencer ON Run.Run_ID = Sample_Sequencer.Run_ID LIMIT 1"))
    columns <- dbListFields(res)
    dbClearResult(res)
    dbDisconnect(con)
    kolomn <- c()
    for(col in columns){
      if(!grepl("ID", col)){
        kolomn <- c(kolomn, col)
      }
    }
    checkboxGroupInput("columns_sample", "Columns", kolomn, selected = kolomn[1:length(kolomn)])
  })
  output$Lane_columns <- renderUI({
    con <- dbConnect(RMySQL::MySQL(), group="trendngs")
    res <- suppressWarnings(dbSendQuery(con, "SELECT Run.Run, Run.Sequencer, Run_per_Lane.* FROM Run JOIN Run_per_Lane ON Run.Run_ID = Run_per_Lane.Run_ID LIMIT 1"))
    columns <- dbListFields(res)
    dbClearResult(res)
    dbDisconnect(con)
    kolomn <- c()
    for(col in columns){
      if(!grepl("ID", col)){
        kolomn <- c(kolomn, col)
      }
    }
    checkboxGroupInput("columns_lane", "Columns", kolomn, selected = kolomn[1:length(kolomn)])
  })

  plot_sample_seq <-function(x_var, y_var, titel, y_lab){
    day_min <- as.numeric(input$date_input1[1])
    day_max <- as.numeric(input$date_input1[2])
    sub_data <- query_sample_seq(x_var,y_var,day_min,day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer1)
    cuttoff <- data.frame(x = c(-Inf, Inf), y= 80, cuttoff = factor(80))
    if(y_var == "PCT_Q30_bases"){
      ggplot(sub_data, aes_string(x=x_var,y=y_var,group=x_var)) + geom_point(shape=1, aes(colour=Sequencer)) + geom_hline(aes(yintercept = 80, linetype = "Q30 - 80%"), colour = "black", size=1)  + stat_summary(fun.y="mean", colour="black", size=3, geom="point") + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="loess") + ggtitle(titel)  + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1, size = 10), axis.text.y = element_text(size=12), axis.title = element_text(size=18), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges1$x, ylim = ranges1$y, expand = TRUE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", values = cols_sequencer) + guides(color=guide_legend(override.aes=list(fill=NA))) + scale_linetype_manual(name = "Cut-off", values = c(1,1), guide = guide_legend(override.aes = list(colour = c("black"))))
    }else{
      ggplot(sub_data, aes_string(x=x_var,y=y_var,group=x_var)) + geom_point(shape=1, aes(colour=Sequencer))  + stat_summary(fun.y="mean", colour="black", size=3, geom="point") + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="loess") + ggtitle(titel)  + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1, size = 10), axis.text.y = element_text(size=12), axis.title = element_text(size=18), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges1$x, ylim = ranges1$y, expand = TRUE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", values = cols_sequencer) + guides(color=guide_legend(override.aes=list(fill=NA)))
    }
  }
  output$Run_Q30 <- renderPlot({
    plot_sample_seq("Run", "PCT_Q30_bases", "Percentage Q30", "Percentage Q30")
  })
  output$Run_MQS <- renderPlot({
    plot_sample_seq("Run", "Mean_Quality_Score", "Mean Quality Score", "Mean Quality Score")
  })
  output$Run_Bar <- renderPlot({
    plot_sample_seq("Run", "PCT_one_mismatch_barcode", "Percentage One Mismatch Barcode", "% one mismatch barcode")
  })
  output$Run_PF <- renderPlot({
    x_var <- "Run"
    y_var <- "PCT_PF_Cluster"
    titel <- "Percentage PF Clusters"
    y_lab <- "% PF Clusters"
    day_min <- as.numeric(input$date_input1[1])
    day_max <- as.numeric(input$date_input1[2])
    sub_data <- query_run(x_var,y_var,day_min,day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer1)
    ggplot(sub_data, aes_string(x=x_var,y=y_var,group=x_var)) + geom_point(shape=19, aes(colour=Sequencer)) + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="loess", se=FALSE) + ggtitle(titel)  + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), axis.text.y = element_text(size=12), axis.title = element_text(size=18), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges1$x, ylim = ranges1$y, expand = TRUE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", values = cols_sequencer) + guides(color=guide_legend(override.aes=list(fill=NA)))
  })
  
  output$MSQ_Q30 <- renderPlot({
    validate(
      need(input$sequencer1 != 0, "Error: Select a sequencer")
    )
    p
    day_min <- as.numeric(input$date_input1[1])
    day_max <- as.numeric(input$date_input1[2])
    sub_data <- query_sample_seq("Run", "Mean_Quality_Score, PCT_Q30_bases",day_min,day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer1)
    ggplot(sub_data, aes(x = Run)) + geom_point(aes(y = PCT_Q30_bases, colour = Sequencer, shape = "PCT_Q30_bases"),size=3) + geom_point(aes(y = Mean_Quality_Score*2.5, colour=Sequencer, shape = "Mean_Quality_Score"), size = 3) + scale_y_continuous(sec.axis = sec_axis(~./2.5, name = "Mean Quality Score")) + stat_summary(aes(y= PCT_Q30_bases),fun.y="mean", colour="black", size=3, geom="point") + stat_summary(aes(y=Mean_Quality_Score*2.5),fun.y="mean", colour="black", size=3, geom="point") + ylab("Q30 (%)") + geom_smooth(aes(y = Mean_Quality_Score*2.5, group=Sequencer, color=Sequencer), method="loess") + geom_smooth(aes(y=PCT_Q30_bases, group=Sequencer, color=Sequencer), method="loess", linetype="dashed") + scale_colour_manual(name = "Sequencer", values = cols_sequencer) + scale_shape_manual(name = "Parameter", labels = c("Mean Quality Score", "Q30"), values = c(4,1)) + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18), legend.key = element_blank()) + coord_cartesian(xlim = ranges1$x, ylim = ranges1$y, expand = TRUE) + guides(color=guide_legend(override.aes=list(fill=NA)))
  })
  
  brush_run_plot <-function(x_var,y_var){
    brush_xmin <- input$run_brush$xmin
    brush_xmax <- input$run_brush$xmax
    brush_ymin <- input$run_brush$ymin
    brush_ymax <- input$run_brush$ymax
    day_min <- as.numeric(input$date_input1[1])
    day_max <- as.numeric(input$date_input1[2])
    sub_data <- query_sample_seq(x_var,y_var,day_min,day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer1)
    sub_data <- transform(sub_data, plotID = as.numeric(factor(Run)))
    sub_data <- sub_data[order(sub_data$plotID),]
    new_data <- sub_data[which(sub_data$plotID >= brush_xmin & sub_data$plotID <= brush_xmax & sub_data[[y_var]] >= brush_ymin & sub_data[[y_var]] <= brush_ymax), c("Lane","Sample_name","Project","PCT_Q30_bases","PCT_PF_Cluster", "Mean_Quality_Score", "PCT_one_mismatch_barcode", "Run", "Sequencer")]
    datatable(new_data, filter = 'top', rownames = FALSE, colnames = c("Lane","Sample name", "Project", "% Q30", "% PF Clusters", "Mean Quality Score","% one mismatch barcode", "Run", "Sequencer" ))
    # str(input$run_brush)
  }
  output$Run_Q30_brushed <- DT::renderDataTable({
    brush_run_plot("Lane, Sample_name, Project, PCT_PF_Cluster,Run,Mean_Quality_Score,PCT_one_mismatch_barcode","PCT_Q30_bases")
  })
  output$Run_MQS_brushed <- DT::renderDataTable({
    brush_run_plot("Lane, Sample_name, Project, PCT_PF_Cluster,PCT_Q30_bases,Run,PCT_one_mismatch_barcode","Mean_Quality_Score")
  })
  output$Run_Bar_brushed <- DT::renderDataTable({
    brush_run_plot("Lane, Sample_name, Project,PCT_PF_Cluster,PCT_Q30_bases,Mean_Quality_Score,Run", "PCT_one_mismatch_barcode")
  })
  output$Run_PF_brushed <- DT::renderDataTable({
    brush_run_plot("Lane, Sample_name, Project,PCT_one_mismatch_barcode ,PCT_Q30_bases,Mean_Quality_Score,Run", "PCT_PF_Cluster")
  })
  
  plot_lane_run <- function(x_var, y_var, titel, y_lab){
    day_min <- as.numeric(input$date_input2[1])
    day_max <- as.numeric(input$date_input2[2])
    sub_data <- query_run_lane(x_var, y_var, day_min, day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer2& Lane %in% input$lanes)
    ggplot(sub_data, aes_string(x=x_var, y=y_var, group=x_var)) + geom_point(aes(colour = Lane, shape= Sequencer), size=3) + geom_smooth(aes(group = Lane, colour = Lane), method = "loess", se=FALSE)  + scale_colour_manual(name = "Lanes", labels = input$lanes, values = cols_lanes) + scale_shape_manual(name= "Sequencer", values = shape_sequencer) + guides(color=guide_legend(override.aes=list(fill=NA))) + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1, size = 10), axis.text.y = element_text(size=12), axis.title = element_text(size=18), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18))+ ylab(y_lab)
  }
  output$Lane_Q30_line <- renderPlot({
    plot_lane_run("Run", "PCT_Q30_bases", "Percentage Q30 per lane", "Percentage Q30")
  })
  output$Lane_MQS_line <- renderPlot({
    plot_lane_run("Run", "Mean_Quality_Score", "Mean Quality Score per Lane", "Mean Quality Score")
  })

  brush_lane_plot <- function(x_var, y_var){
    brush_xmin <- input$lane_brush$xmin
    brush_xmax <- input$lane_brush$xmax
    brush_ymin <- input$lane_brush$ymin
    brush_ymax <- input$lane_brush$ymax
    day_min <- as.numeric(input$date_input2[1])
    day_max <- as.numeric(input$date_input2[2])
    sub_data <- query_run_lane(x_var,y_var,day_min,day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer2 & Lane %in% input$lanes)
    sub_data <- transform(sub_data, plotID = as.numeric(factor(Run)))
    sub_data <- sub_data[order(sub_data$plotID),]
    new_data <- sub_data[which(sub_data$plotID >= brush_xmin & sub_data$plotID <= brush_xmax & sub_data[[y_var]] >= brush_ymin & sub_data[[y_var]] <= brush_ymax), c("Run","Lane","PF_Clusters","PCT_of_lane","PCT_perfect_barcode","PCT_one_mismatch_barcode","Yield_Mbases","PCT_PF_Clusters","PCT_Q30_bases","Mean_Quality_Score","Sequencer")]
    datatable(new_data, filter = 'top', rownames = FALSE, colnames = c("Run", "Lane","PF Clusters", "% of the lane", "% perfect barcode", "% one mismatch barcode", "Yield (Mbases)","% PF Clusters", "% Q30","Mean Quality Score", "Sequencer" ))
  }
  output$Lane_Q30_brushed <- DT::renderDataTable({
    brush_lane_plot("Lane,PF_Clusters,PCT_of_lane,PCT_perfect_barcode,PCT_one_mismatch_barcode,Run_per_Lane.Yield_Mbases,PCT_PF_Clusters,Mean_Quality_Score,Run", "PCT_Q30_bases")
  })
  output$Lane_MQS_brushed <- DT::renderDataTable({
    brush_lane_plot("Lane,PF_Clusters,PCT_of_lane,PCT_perfect_barcode,PCT_one_mismatch_barcode,Run_per_Lane.Yield_Mbases,PCT_PF_Clusters,PCT_Q30_bases,Run", "Mean_Quality_Score")
  })
    
  plot_sample_proc <- function(x_var,y_var,titel,y_lab){
    day_min <- as.numeric(input$date_input3[1])
    day_max <- as.numeric(input$date_input3[2])
    sub_data <- query_sample_proc(x_var,y_var,day_min,day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer3)
    if(y_var == "Number_variants"){
      sub_data$Number_variants <- as.numeric(sub_data$Number_variants)
    }
    ggplot(sub_data, aes_string(x=x_var,y=y_var,group=x_var)) + geom_point(shape=1, aes(colour=Sequencer)) + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="loess") + ggtitle(titel)  + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1, size = 10), axis.text.y = element_text(size=12), axis.title = element_text(size=18), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges3$x, ylim = ranges3$y, expand = TRUE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", values = cols_sequencer) + guides(color=guide_legend(override.aes=list(fill=NA)))
  }
  output$Proc_dup <- renderPlot({
    plot_sample_proc("Run", "Duplication","Duplication","Percentage Duplication")
  })
  output$Proc_selected <- renderPlot({
    plot_sample_proc("Run","PCT_selected_bases","Percentage selected bases","% selected bases")
  })
  output$Proc_meantarget <- renderPlot({
    plot_sample_proc("Run", "Mean_target_coverage", "Mean target coverage", "% mean target coverage")
  })
  output$Proc_meanbait <- renderPlot({
    plot_sample_proc("Run", "Mean_bait_coverage", "Mean bait coverage", "% mean bait coverage")
  })
  output$Proc_target20X <- renderPlot({
    plot_sample_proc("Run", "PCT_target_bases_20X", "Percentage target bases 20X", "% target bases 20X")
  })
  output$Proc_ATdrop <- renderPlot({
    plot_sample_proc("Run", "AT_dropout", "Percentage AT dropout", "% AT dropout")
  })
  output$Proc_GCdrop <- renderPlot({
    plot_sample_proc("Run", "GC_dropout", "Percentage GC dropout", "% GC dropout")
  })
  output$Proc_variants <- renderPlot({
    plot_sample_proc("Run", "Number_variants", "Number of variants", "Number of variants")
  })
  
  plot_sample_math <- function(a, b, x_var, y_var, titel,y_lab){
    day_min <- as.numeric(input$date_input3[1])
    day_max <- as.numeric(input$date_input3[2])
    sub_data <- query_math(a, b, x_var,y_var,day_min,day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer3)
    ggplot(sub_data, aes_string(x=x_var,y=y_var,group=x_var)) + geom_point(shape=1, aes(colour=Sequencer)) + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="loess") + ggtitle(titel)  + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1, size = 10), axis.text.y = element_text(size=12), axis.title = element_text(size=18), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges3$x, ylim = ranges3$y, expand = TRUE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", values = cols_sequencer) + guides(color=guide_legend(override.aes=list(fill=NA)))
  }
  output$Proc_dbSNP <- renderPlot({
    plot_sample_math("dbSNP_variants", "Number_variants", "Run", "PCT_dbSNP_variants", "Percentage dbSNP variants", "% dbSNP variants")
  })
  output$Proc_PASS <- renderPlot({
    plot_sample_math("PASS_variants", "Number_variants", "Run", "PCT_PASS_variants", "Percentage PASS variants", "% PASS variants")
  })
  
  brush_sample_proc_plot <- function(x_var,y_var){
    brush_xmin <- input$proc_brush$xmin
    brush_xmax <- input$proc_brush$xmax
    brush_ymin <- input$proc_brush$ymin
    brush_ymax <- input$proc_brush$ymax
    day_min <- as.numeric(input$date_input1[1])
    day_max <- as.numeric(input$date_input1[2])
    sub_data <- query_sample_proc(x_var,y_var,day_min,day_max)
    sub_data <- subset(sub_data, Sequencer %in% input$sequencer3)
    if(y_var == "Number_variants"){
      sub_data$Number_variants <- as.numeric(sub_data$Number_variants)
    }
    if(y_var == "(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants'"){
      y_var = "PCT_dbSNP_variants"
    }
    if(y_var == "(PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'"){
      y_var = "PCT_PASS_variants"
    }
    sub_data <- transform(sub_data, plotID = as.numeric(factor(Run)))
    sub_data <- sub_data[order(sub_data$plotID),]
    new_data <- sub_data[which(sub_data$plotID >= brush_xmin & sub_data$plotID <= brush_xmax & sub_data[[y_var]] >= brush_ymin & sub_data[[y_var]] <= brush_ymax), c("Run", "Sample_name","PCT_selected_bases","Mean_bait_coverage","Mean_target_coverage","PCT_target_bases_20X","AT_dropout","GC_dropout","Duplication","Number_variants","PCT_dbSNP_variants","PCT_PASS_variants", "Sequencer")]
    datatable(new_data, filter = 'top', rownames = FALSE, colnames = c("Run", "Sample name","% selected bases","Mean bait coverage","Mean target coverage","% target bases 20X","% AT dropout","% GC dropout","% Duplicates","Number of variants","% dbSNP variants","% PASS variants", "Sequencer" ))
  }
  output$Proc_dup_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, PCT_selected_bases, Mean_bait_coverage, Mean_target_coverage, PCT_target_bases_20X, AT_dropout,GC_dropout,Number_variants, (dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","Duplication")
  })
  output$Proc_selected_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_bait_coverage, Mean_target_coverage, PCT_target_bases_20X, AT_dropout,GC_dropout,Number_variants,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","PCT_selected_bases")
  })
  output$Proc_meantarget_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_bait_coverage,PCT_selected_bases, PCT_target_bases_20X, AT_dropout,GC_dropout,Number_variants,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","Mean_target_coverage")
  })
  output$Proc_meanbait_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_target_coverage,PCT_selected_bases, PCT_target_bases_20X, AT_dropout,GC_dropout,Number_variants,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","Mean_bait_coverage")
  })
  output$Proc_target20X_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_target_coverage,PCT_selected_bases, Mean_bait_coverage, AT_dropout,GC_dropout,Number_variants,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","PCT_target_bases_20X")
  })
  output$Proc_ATdrop_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_target_coverage,PCT_selected_bases, Mean_bait_coverage, PCT_target_bases_20X,GC_dropout,Number_variants,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","AT_dropout")
  })
  output$Proc_GCdrop_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_target_coverage,PCT_selected_bases, Mean_bait_coverage, PCT_target_bases_20X, AT_dropout,Number_variants,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","GC_dropout")
  })
  output$Proc_variants_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_target_coverage,PCT_selected_bases, Mean_bait_coverage, PCT_target_bases_20X, AT_dropout, GC_dropout,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","Number_variants")
  })
  output$Proc_dbSNP_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_target_coverage,PCT_selected_bases, Mean_bait_coverage, PCT_target_bases_20X, AT_dropout, GC_dropout,Number_variants, (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'","(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants'")
  })
  output$Proc_PASS_brushed <- DT::renderDataTable({
    brush_sample_proc_plot("Run, Sample_name, Duplication, Mean_target_coverage,PCT_selected_bases, Mean_bait_coverage, PCT_target_bases_20X, AT_dropout, GC_dropout,Number_variants,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants'","(PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'")
  })
  
  output$run_table <- DT::renderDataTable({
    data <- query_run_table("Lane,Project,Sample_name,Barcode_sequence,PF_Clusters,PCT_of_lane,PCT_perfect_barcode,PCT_one_mismatch_barcode,Sample_Sequencer.Yield_Mbases,PCT_PF_Clusters,PCT_Q30_bases,Mean_Quality_Score")
    data <- data[, input$columns_sample, drop=FALSE]
    options = list(autoWidth=FALSE)
    DT::datatable(data, filter = 'top', rownames = FALSE, extensions = 'FixedHeader', options = list(fixedHeader = TRUE))
  })
  output$lane_table <- DT::renderDataTable({
    data <- query_lane_table("Lane,PF_Clusters,PCT_of_lane,PCT_perfect_barcode,PCT_one_mismatch_barcode,Run_per_Lane.Yield_Mbases,PCT_PF_Clusters,PCT_Q30_bases,Mean_Quality_Score")
    data <- data[, input$columns_lane, drop=FALSE]
    options = list(autoWidth=FALSE)
    DT::datatable(data,filter = 'top', rownames = FALSE, extensions = 'FixedHeader', options = list(fixedHeader = TRUE))
  })
  output$processed_table <- DT::renderDataTable({
    data <- query_processed_table("Sample_Processed.*")
    # data <- query_processed_table("Sample_name,Total_number_of_reads,Percentage_reads_mapped,Total_reads,PF_reads,PF_unique_reads,PCT_PF_reads,PCT_PF_UQ_reads,PCT_UQ_reads_aligned,PCT_PF_UQ_reads_aligned,PF_UQ_bases_aligned,On_bait_bases,Near_bait_bases,Off_bait_bases,On_target_bases,PCT_selected_bases,PCT_off_bait,On_bait_vs_selected,Mean_bait_coverage,Mean_target_coverage,PCT_usable_bases_on_bait,PCT_usable_bases_on_target,Fold_enrichment,Zero_CVG_targets_PCT,Fold_80_base_penalty,PCT_target_bases_2X,PCT_target_bases_10X,PCT_target_bases_20X,PCT_target_bases_30X,PCT_target_bases_40X,PCT_target_bases_50X,PCT_target_bases_100X,HS_library_size,HS_penalty_10X,HS_penalty_20X,HS_penalty_30X,HS_penalty_40X,HS_penalty_50X,HS_penalty_100X,AT_dropout,GC_dropout,Duplication,Number_variants,(dbSNP_variants / Number_variants)*100 AS 'PCT_dbSNP_variants' , (PASS_variants / Number_variants)*100 AS 'PCT_PASS_variants'")
    data <- data[, input$columns_processed, drop=FALSE]
    options = list(autoWidth=FALSE)
    DT::datatable(data,filter = 'top', rownames = FALSE, extensions = 'FixedHeader', options = list(fixedHeader = TRUE))
  })

  output$down_sample_seq <- downloadHandler(
    filename = function(){
      paste("Sample_sequencer_data", ".csv", sep ="")
    },
    content = function(file){
      data_filter = input$run_table_rows_all
      write.csv(query_run_table("Lane,Project,Sample_name,Barcode_sequence,PF_Clusters,PCT_of_lane,PCT_perfect_barcode,PCT_one_mismatch_barcode,Sample_Sequencer.Yield_Mbases,PCT_PF_Clusters,PCT_Q30_bases,Mean_Quality_Score")[data_filter, input$columns_sample, drop = FALSE], file, row.names = FALSE)
    }
  )
  output$down_lane_seq <- downloadHandler(
    filename = function(){
      paste("Lane sequencer data", ".csv", sep = "")
    },
    content = function(file){
      data_filter = input$lane_table_rows_all
      write.csv(query_lane_table("Lane,PF_Clusters,PCT_of_lane,PCT_perfect_barcode,PCT_one_mismatch_barcode,Run_per_Lane.Yield_Mbases,PCT_PF_Clusters,PCT_Q30_bases,Mean_Quality_Score")[data_filter, input$columns_lane, drop=FALSE],file,row.names = FALSE)
    }
  )
  output$down_sample_proc <- downloadHandler(
    filename = function(){
      paste("Processed data", ".csv", sep = "")
    },
    content = function(file){
      data_filter = input$processed_table_rows_all
      write.csv(query_processed_table("Sample_name,Total_number_of_reads,Percentage_reads_mapped,Total_reads,PF_reads,PF_unique_reads,PCT_PF_reads,PCT_PF_UQ_reads,PCT_UQ_reads_aligned,PCT_PF_UQ_reads_aligned,PF_UQ_bases_aligned,On_bait_bases,Near_bait_bases,Off_bait_bases,On_target_bases,PCT_selected_bases,PCT_off_bait,On_bait_vs_selected,Mean_bait_coverage,Mean_target_coverage,PCT_usable_bases_on_bait,PCT_usable_bases_on_target,Fold_enrichment,Zero_CVG_targets_PCT,Fold_80_base_penalty,PCT_target_bases_2X,PCT_target_bases_10X,PCT_target_bases_20X,PCT_target_bases_30X,PCT_target_bases_40X,PCT_target_bases_50X,PCT_target_bases_100X,HS_library_size,HS_penalty_10X,HS_penalty_20X,HS_penalty_30X,HS_penalty_40X,HS_penalty_50X,HS_penalty_100X,AT_dropout,GC_dropout,Duplication,Number_variants,PCT_dbSNP_variants,PCT_PASS_variants")[data_filter, input$columns_processed,drop=FALSE],file,row.names = FALSE)
    }
  )
  ranges1 <- reactiveValues(x = NULL, y= NULL)
  ranges2 <- reactiveValues(x = NULL, y= NULL)
  ranges3 <- reactiveValues(x = NULL, y= NULL)
  observeEvent(input$run_dblclick, {
    brush <- input$run_brush
    if (!is.null(brush)){
      ranges1$x <- c(brush$xmin, brush$xmax)
      ranges1$y <- c(brush$ymin, brush$ymax)
    }else{
      ranges1$x <- NULL
      ranges1$y <- NULL
    }
  })
  observeEvent(input$lane_dblclick, {
    brush <- input$lane_brush
    if (!is.null(brush)){
      ranges2$x <- c(brush$xmin, brush$xmax)
      ranges2$y <- c(brush$ymin, brush$ymax)
    }else{
      ranges2$x <- NULL
      ranges2$y <- NULL
    }
  })
  observeEvent(input$proc_dblclick, {
    brush <- input$proc_brush
    if (!is.null(brush)){
      ranges3$x <- c(brush$xmin, brush$xmax)
      ranges3$y <- c(brush$ymin, brush$ymax)
    }else{
      ranges3$x <- NULL
      ranges3$y <- NULL
    }
  })
  
  # session$onSessionEnded(stopApp)
}


# boxplot_lane_run <- function(x_var, y_var, titel, y_lab){
#   day_min <- as.numeric(input$date_input2[1])
#   day_max <- as.numeric(input$date_input2[2])
#   sub_data <- query_run_lane(x_var, y_var, day_min, day_max)
#   sub_data <- subset(sub_data, Sequencer %in% input$sequencer2& Lane %in% input$lanes)
#   ggplot(sub_data, aes_string(x=x_var, y=y_var, fill="Sequencer", colour="Sequencer")) + geom_boxplot(alpha=.5, outlier.colour = NA, position = position_dodge(width = .8)) + geom_point(position = position_jitterdodge(jitter.width=.15, dodge.width = .8)) + scale_fill_manual(name = "Sequencer", values = cols_sequencer) + theme(axis.text.x=element_text(hjust=1, vjust=1), axis.text.y = element_text(size=12), axis.title = element_text(size=18), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + ggtitle(titel) + coord_cartesian(xlim = ranges2$x, ylim = ranges2$y, expand = TRUE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", values = cols_sequencer) + guides(color=guide_legend(override.aes=list(fill=NA)))
# }
# output$Lane_Q30 <- renderPlot({
#   boxplot_lane_run("Lane", "PCT_Q30_bases", "Percentage Q30 per Lane", "Percentage Q30")
# })
# output$Lane_MQS <- renderPlot({
#   boxplot_lane_run("Lane", "Mean_Quality_Score", "Mean Quality Score per Lane", "Mean Quality Score")
# })
# 
# plot_down_proc <- function(x_var,y_var,titel,y_lab){
#   day_min <- as.numeric(input$date_input3[1])
#   day_max <- as.numeric(input$date_input3[2])
#   sub_data <- query_sample_proc(x_var,y_var,day_min,day_max)
#   sub_data <- subset(sub_data, Sequencer %in% input$sequencer3)
#   ggplot(sub_data, aes_string(x=x_var,y=y_var,group=x_var)) + geom_point(shape=1, aes(colour=Sequencer)) + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="loess") + ggtitle(titel) + coord_cartesian(xlim = ranges3$x, ylim = ranges3$y, expand = TRUE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", values = cols_sequencer) + guides(color=guide_legend(override.aes=list(fill=NA))) + theme(axis.text.x=element_text(size=6,angle=80, hjust=1, vjust=1))
# }
# 
# output$download_plot3 <- downloadHandler(
#   filename = function(){
#     paste("Processed plot", '.png', sep = '')
#   },
#   content = function(file){
#     if(input$tab_proc == "Proc_dup"){
#       ggsave(file, plot = plot_down_proc("Run", "Duplication","Duplication","Percentage Duplication"))
#     }
#     if(input$tab_proc == "Proc_selected"){
#       ggsave(file, plot = plot_down_proc("Run", "PCT_selected_bases","Percentage selected bases","% selected bases"))
#     }
#     if(input$tab_proc == "Proc_MTC"){
#       ggsave(file, plot = plot_down_proc("Run", "Mean_target_coverage", "Mean target coverage", "% mean target coverage"))
#     }
#   }
# )