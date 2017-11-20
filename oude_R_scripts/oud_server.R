# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
# TAQC
library(shiny)
library(ggplot2)
library(DT)

tables <- function() {
  run_table = read.table("/home/cog/aluesink/Documents/TAQC/run_table1.txt", header = TRUE)
  sample_lane_table = read.table("/home/cog/aluesink/Documents/TAQC/sample_lane_table.txt", header = TRUE)
  processed_table = read.table("/home/cog/aluesink/Documents/TAQC/processed_sample.txt", header = TRUE)
  
  processed_table <- processed_table[processed_table$Run!="Test_100_exomes",]
  # sample_lane_table <- sample_lane_table[sample_lane_table$Project!="DEFAULT",]
  
  run_table$Date <- NULL
  run_table$asDate <- NULL
  
  for (i in 1:nrow(run_table)){
    run_table$Date[i] <- unlist(strsplit(as.character(run_table$Run[i]),"_"))[1]
    run_table$asDate[i] <- as.Date(run_table$Date[i], "%y%m%d", origin="00-00-00")
    run_table$Date[i] <- format.Date(as.Date(run_table$Date[i], "%y%m%d"), "%d/%m/%Y")
    run_table$Lane[i] <- toString(run_table$Lane[i])
  }
  
  sample_lane_table$Date <- NULL
  sample_lane_table$asDate <- NULL
  for (i in 1:nrow(sample_lane_table)){
    sample_lane_table$Date[i] <- unlist(strsplit(as.character(sample_lane_table$Run[i]),"_"))[1]
    sample_lane_table$asDate[i] <- as.Date(sample_lane_table$Date[i], "%y%m%d", origin="00-00-00")
    sample_lane_table$Date[i] <- format.Date(as.Date(sample_lane_table$Date[i], "%y%m%d"), "%d/%m/%Y")
  }
  
  processed_table$Date <- NULL
  processed_table$asDate <- NULL
  processed_table$Sequencer <- NA
  hiseq <- c("hiseq_umc01")
  nextseq1 <- c("nextseq_umc01")
  nextseq2 <- c("nextseq_umc02")
  
  for(i in 1:nrow(processed_table)){
    processed_table$Date[i] <- unlist(strsplit(as.character(processed_table$Run[i]),"_"))[1]
    processed_table$asDate[i] <- as.Date(processed_table$Date[i], "%y%m%d", origin="00-00-00")
    processed_table$Date[i] <- format.Date(as.Date(processed_table$Date[i], "%y%m%d"), "%d/%m/%Y")
    
    if(grepl("D00267",processed_table$Run[i]) == TRUE){
      processed_table$Sequencer[i] <- hiseq
    }
    else if(grepl("NB501012", processed_table$Run[i]) == TRUE){
      processed_table$Sequencer[i] <- nextseq1
    }
    else if(grepl("NB501039", processed_table$Run[i]) == TRUE){
      processed_table$Sequencer[i] <- nextseq2
    }
  }
  
  # sample_lane_table$len_barcode <- NULL
  # for(i in unique(sample_lane_table[, "Barcode_sequence"])){
  #   sample_lane_table$len_barcode[sample_lane_table[, "Barcode_sequence"]==i] <- nchar(i)
  # }
  
  projects <- unique(sample_lane_table[,"Project"])
  run_table <- run_table[order(run_table$asDate), ]
  processed_table <- processed_table[order(processed_table$asDate), ]
  
  # tabellen <- list("run_table" = run_table, "sample_lane_table" = sample_lane_table, "processed_table" = processed_table)
  tabellen <- list()
  tabellen$run <- run_table
  tabellen$sample <- sample_lane_table
  tabellen$processed <- processed_table
  return(tabellen)
}

function(input, output, session) {
  tabellen <- list()
  tabellen <- tables()
  run_table <- tabellen$run
  sample_lane_table <- tabellen$sample
  processed_table <- tabellen$processed
  
  cols_sequencer <- c("hiseq_umc01" = "#009E73", "nextseq_umc01" = "#0072B2", "nextseq_umc02" = "#D55E00")
  cols_lanes <- c("1" = "darkred", "2" = "darkgoldenrod2", "3" = "navyblue", "4" = "cyan3")
  
  output$plotui <- renderUI({
    brush = brushOpts(
      id = "plot_brush",
      direction = "xy",
      resetOnNew = TRUE
    )
  })
  
  brush_plot <- function(y_var){
    brush_xmin <- input$plot_brush$xmin
    brush_xmax <- input$plot_brush$xmax
    brush_ymin <- input$plot_brush$ymin
    brush_ymax <- input$plot_brush$ymax
    days <- format(seq(as.Date(input$sliderData[1], "%Y/%m/%d"), as.Date(input$sliderData[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(sample_lane_table, Date %in% days & Sequencer %in% input$sequencer)
    sub_data <- transform(sub_data, Run_ID = as.numeric(factor(Run)))
    sub_data <- sub_data[order(sub_data$Run_ID), ]
    if(!is.null(brush_xmax)){
      new_data <- sub_data[which(sub_data$Run_ID >= brush_xmin & sub_data$Run_ID <= brush_xmax & sub_data[[y_var]] >= brush_ymin & sub_data[[y_var]] <= brush_ymax), c("Lane","Sample","Project","X._PF_Clusters", "X._._Q30_bases", "Mean_Quality_Score", "Run", "Sequencer")]
    }else{
      new_data <- sub_data["",c("Lane","Sample","Project","X._PF_Clusters", "X._._Q30_bases", "Mean_Quality_Score", "Run", "Sequencer")]
    }
    datatable(new_data, filter = 'top', rownames = FALSE)
  }
  output$plot_brushed1 <- DT::renderDataTable({
    brush_plot("X._._Q30_bases")
  })
  output$plot_brushed2 <- DT::renderDataTable({
    brush_plot("Mean_Quality_Score")
  })
  output$plot_brushed3 <- DT::renderDataTable({
    brush_plot("X._PF_Clusters")
  })
  
  plot_run <- function(x_var, y_var, titel, y_lab, cutoff){
    if(!is.null(cutoff)){
      cut_off <- data.frame(y_in = cutoff)
    }else{
      cut_off = NULL
    }
    validate(
      need(input$sequencer != 0, "Error: Select a sequencer")
    )
    days <- format(seq(as.Date(input$sliderData[1], "%Y/%m/%d"), as.Date(input$sliderData[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(sample_lane_table, Date %in% days & Sequencer %in% input$sequencer)
    if(!is.null(cut_off)){
      ggplot(sub_data, aes_string(x=x_var, y=y_var, group=x_var)) + geom_point(shape=1, aes(colour=Sequencer)) + geom_hline(data = cut_off, aes(yintercept=y_in, linetype = "Cut-off"), show.legend = TRUE)  + stat_summary(fun.y="mean", colour="black", size=3, geom="point") + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="lm") + ggtitle(titel)  + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges1$x, ylim = ranges1$y, expand = FALSE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", labels = input$sequencer, values = cols_sequencer)  + guides(color=guide_legend(override.aes=list(fill=NA)))
    }else{
      ggplot(sub_data, aes_string(x=x_var, y=y_var, group=x_var)) + geom_point(shape=1, aes(colour=Sequencer)) + stat_summary(fun.y="mean", colour="black", size=3, geom="point") + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="lm") + ggtitle(titel)  + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges1$x, ylim = ranges1$y, expand = FALSE) + ylab(y_lab) + scale_colour_manual(name = "Sequencer", labels = input$sequencer, values = cols_sequencer)  + guides(color=guide_legend(override.aes=list(fill=NA)))
    }
  }
  output$Run_Q30 <- renderPlot({
    plot_run("Run", "X._._Q30_bases", "Percentage based \u2265 Q30", "% \u2265 Q30", 80)
  })
  output$Run_MQS <- renderPlot({
    plot_run("Run", "Mean_Quality_Score", "Mean Quality Score", "Mean Quality Score", NULL)
  })
  output$Run_PF <- renderPlot({
    validate(
      need(input$sequencer != 0, "Error: Select a sequencer")
    )
    days <- format(seq(as.Date(input$sliderData[1], "%Y/%m/%d"), as.Date(input$sliderData[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(run_table, Date %in% days & Sequencer %in% input$sequencer)
    ggplot(sub_data, aes_string(x="Run", y="X._PF_Clusters", group="Run")) + geom_point(shape=1, aes(colour=Sequencer)) + stat_summary(fun.y="mean", colour="black", size=3, geom="point") + geom_smooth(aes(group=Sequencer, colour=Sequencer), method="lm") + ggtitle("Percentage Pass Filter Cluster") + ylab("Pass Filter Cluster (%)") + scale_colour_manual(name = "Sequencer", labels = input$sequencer, values = c("#009E73", "#0072B2", "#D55E00")) + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges1$x, ylim = ranges1$y, expand = FALSE) + guides(color=guide_legend(override.aes=list(fill=NA)))
    
    # plot_run("Run", "X._PF_Clusters", "Percentage Pass Filter Cluster", "Pass Filter Cluster (%)", NULL)
  })
  
  
  brush_plot_sample <- function(y_var){
    brush_xmin <- input$plot_brush1$xmin
    brush_xmax <- input$plot_brush1$xmax
    brush_ymin <- input$plot_brush1$ymin
    brush_ymax <- input$plot_brush1$ymax
    days <- format(seq(as.Date(input$sliderData2[1], "%Y/%m/%d"), as.Date(input$sliderData2[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(processed_table, Date %in% days & Sequencer %in% input$sequencer & Methode %in% input$methode)
    sub_data <- transform(sub_data, Run_ID = as.numeric(factor(Run)))
    sub_data <- sub_data[order(sub_data$Run_ID), ]
    if(!is.null(brush_xmax)){
      new_data <- sub_data[which(sub_data$Run_ID >= brush_xmin & sub_data$Run_ID <= brush_xmax & sub_data[[y_var]] >= brush_ymin & sub_data[[y_var]] <= brush_ymax), c("Sample","BAIT_SET", "PCT_SELECTED_BASES","MEAN_BAIT_COVERAGE","MEAN_TARGET_COVERAGE", "PCT_TARGET_BASES_20X", "AT_DROPOUT", "Run", "Duplication", "Sequencer")]
    }else{
      new_data <- sub_data["",c("Sample","BAIT_SET", "PCT_SELECTED_BASES","MEAN_BAIT_COVERAGE","MEAN_TARGET_COVERAGE", "PCT_TARGET_BASES_20X", "AT_DROPOUT", "Run", "Duplication", "Sequencer")]
    }
    datatable(new_data, filter = 'top', rownames = FALSE)
  }
  output$plot_brush_sample1 <- DT::renderDataTable({
    brush_plot_sample("AT_DROPOUT")
  })
  output$plot_brush_sample2 <- DT::renderDataTable({
    brush_plot_sample("PCT_TARGET_BASES_20X")
  })
  output$plot_brush_sample3 <- DT::renderDataTable({
    brush_plot_sample("Duplication")
  })
  
  plot_sample <- function(x_var, y_var, titel, y_lab, limit){
    validate(
      need(input$sequencer1 != 0, "Error: Select a sequencer"),
      need(input$methode != 0, "Error: Select a methode")
    )
    days <- format(seq(as.Date(input$sliderData2[1], "%Y/%m/%d"), as.Date(input$sliderData2[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(processed_table, Date %in% days & Sequencer %in% input$sequencer1 & Methode %in% input$methode)
    ggplot(sub_data, aes_string(x=x_var, y=y_var, group=x_var)) + geom_point(shape=1, aes(colour=Sequencer)) + geom_smooth(aes(group=Sequencer, colour =Sequencer), method="lm") + ggtitle(titel) + scale_y_continuous(name=y_lab, breaks = waiver(), limits = c(0,(max(processed_table[[y_var]])+limit))) + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18)) + coord_cartesian(xlim = ranges2$x, ylim = ranges2$y, expand = FALSE)  + scale_colour_manual(name = "Sequencer", labels = input$sequencer1, values = cols_sequencer)  + guides(color=guide_legend(override.aes=list(fill=NA)))
  }
  output$Sample_ATdrop <- renderPlot({
    plot_sample(input$datatype,"AT_DROPOUT","Percentage AT dropout", "AT dropout (%)", 2)
  })
  output$Perc_20X <- renderPlot({
    plot_sample(input$datatype, "PCT_TARGET_BASES_20X", "Percentage Target Bases 20X", "% Target Bases 20X", 0.1)
  })
  output$Perc_dup <- renderPlot({
    plot_sample(input$datatype, "Duplication", "Percentage Duplication", "Duplication (%)", 10)
  })
  
  
  output$PF_Q30 <- renderPlot({
    days <- format(seq(as.Date(input$sliderData3[1], "%Y/%m/%d"), as.Date(input$sliderData3[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(sample_lane_table, Date %in% days & Sequencer %in% input$sequencer2)
    # cbPalette <- c("#009E73", "#0072B2", "#D55E00")
    ggplot(sub_data, aes(x = Run)) + geom_point(aes(y = X._._Q30_bases, colour = Sequencer, shape = "X._._Q30_bases"),size=3) + geom_point(aes(y = X._PF_Clusters, colour=Sequencer, shape = "X._PF_Clusters"), size = 3)+ scale_y_continuous(sec.axis = sec_axis(~., name = "Pass Filter Cluster")) + geom_smooth(aes(y =Mean_Quality_Score, group=Sequencer, color=Sequencer), method="lm") + geom_smooth(aes(y=X._._Q30_bases, group=Sequencer, color=Sequencer), method="lm", linetype="dashed")  + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18), legend.key = element_blank()) + coord_cartesian(xlim = ranges3$x, ylim = ranges3$y, expand = FALSE) + scale_colour_manual(name = "Sequencer", labels = input$sequencer2, values = cols_sequencer) + scale_shape_manual(name = "Parameter", labels = c("% Pass Filter Cluster", "Q30"), values = c(1,0)) + guides(color=guide_legend(override.aes=list(fill=NA)))
  })
  output$MQS_Q30 <- renderPlot({
    days <- format(seq(as.Date(input$sliderData3[1], "%Y/%m/%d"), as.Date(input$sliderData3[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(sample_lane_table, Date %in% days & Sequencer %in% input$sequencer2)
    ggplot(sub_data, aes(x = Run)) + geom_point(aes(y = X._._Q30_bases, colour = Sequencer, shape = "X._._Q30_bases"),size=3) + geom_point(aes(y = Mean_Quality_Score, colour=Sequencer, shape = "Mean_Quality_Score"), size = 3) + scale_y_continuous(sec.axis = sec_axis(~./2.5, name = "Mean Quality Score")) + ylab("Q30 (%)") + geom_smooth(aes(y = Mean_Quality_Score, group=Sequencer, color=Sequencer), method="lm") + geom_smooth(aes(y=X._._Q30_bases, group=Sequencer, color=Sequencer), method="lm", linetype="dashed") + scale_colour_manual(name = "Sequencer", labels = input$sequencer2, values = cols_sequencer) + scale_shape_manual(name = "Parameter", labels = c("Mean Quality Score", "Q30"), values = c(1,0)) + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18), legend.key = element_blank()) + coord_cartesian(xlim = ranges3$x, ylim = ranges3$y, expand = FALSE) + guides(color=guide_legend(override.aes=list(fill=NA)))
  })
  
  output$sample_table <- DT::renderDataTable({
    data <- sample_lane_table
    data <- data[, input$colsample, drop=FALSE]
    DT::datatable(data, filter = 'top', rownames = FALSE,
                  options = list(autoWidth = FALSE))
  })
  output$processed_table <- DT::renderDataTable({
    data <- processed_table
    data <- data[, input$colprocessed, drop=FALSE]
    DT::datatable(data, filter = 'top', rownames = FALSE,
                  options = list(autoWidth = FALSE))
  })
  
  output$Lane_Q30 <- renderPlot({
    validate(
      need(input$sequencer3 != 0, "Error: Select a sequencer"),
      need(input$lane != 0, "Error: Select a lane")
    )
    days <- format(seq(as.Date(input$sliderData3[1], "%Y/%m/%d"), as.Date(input$sliderData3[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(run_table, Date %in% days & Sequencer %in% input$sequencer3 & Lane %in% input$lane)
    ggplot(sub_data, aes_string(x="Run", y="X._._Q30_bases", group="Run")) + geom_point(aes(colour= Lane, shape = Sequencer), size =3) + geom_smooth(aes(group = Lane, colour = Lane), method = "lm") + scale_colour_manual(name = "Lanes", labels = input$lane, values = cols_lanes) + scale_shape_manual(name= "Sequencer", labels = input$sequencer3, values = c(0,1,4)) + guides(color=guide_legend(override.aes=list(fill=NA))) + theme(axis.text.x=element_text(angle=80, hjust=1, vjust=1), plot.title = element_text(lineheight=.8, face="bold",size = 30), legend.title = element_text(size=20, face="bold"), legend.text = element_text(size=18))
  })
  output$Box_Lane_Q30 <- renderPlot({
    validate(
      need(input$sequencer3 != 0, "Error: Select a sequencer"),
      need(input$lane != 0, "Error: Select a lane")
    )
    days <- format(seq(as.Date(input$sliderData3[1], "%Y/%m/%d"), as.Date(input$sliderData3[2], "%Y/%m/%d"), by="days"), "%d/%m/%Y")
    sub_data <- subset(run_table, Date %in% days & Sequencer %in% input$sequencer3 & Lane %in% input$lane)
    ggplot(sub_data, aes_string(x="Lane", y="X._._Q30_bases", fill="Sequencer")) + geom_boxplot() + scale_fill_manual(name = "Sequencer", labels = input$sequencer3, values = cols_sequencer)
  })
  
  
  ranges1 <- reactiveValues(x = NULL, y = NULL)
  ranges2 <- reactiveValues(x = NULL, y = NULL)
  ranges3 <- reactiveValues(x = NULL, y = NULL)
  
  observeEvent(input$plot1_dblclick, {
    brush <- input$plot_brush
    if (!is.null(brush)){
      ranges1$x <- c(brush$xmin, brush$xmax)
      ranges1$y <- c(brush$ymin, brush$ymax)
    }else{
      ranges1$x <- NULL
      ranges1$y <- NULL
    }
  })
  observeEvent(input$plot2_dblclick, {
    brush <- input$plot_brush1
    if (!is.null(brush)){
      ranges2$x <- c(brush$xmin, brush$xmax)
      ranges2$y <- c(brush$ymin, brush$ymax)
    }else{
      ranges2$x <- NULL
      ranges2$y <- NULL
    }
  })
  observeEvent(input$plot3_dblclick, {
    brush <- input$plot_brush2
    if (!is.null(brush)){
      ranges3$x <- c(brush$xmin, brush$xmax)
      ranges3$y <- c(brush$ymin, brush$ymax)
    }else{
      ranges3$x <- NULL
      ranges3$y <- NULL
    }
  })
}

