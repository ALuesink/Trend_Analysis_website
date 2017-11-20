library(shiny)
library(DT)

sequencers <- sort(unique(sample_lane_table[, "Sequencer"]))
sequencers_processed <- sort(unique(processed_table[, "Sequencer"]))
sequencers_run <- sort(unique(run_table[, "Sequencer"]))
projects <- unique(sample_lane_table[, "Project"])
projects <- sort(union(projects, c("All")))
length_barcode <- c(6,8)
type <- c("Run", "Sample")
methode <- sort(unique(processed_table[, "Methode"]))
columns_sample <- names(sample_lane_table)
columns_processed <- names(processed_table)
lanes <- sort(unique(run_table[, "Lane"]))

shinyUI(
  fluidPage(
    tags$head(
      tags$style(HTML("
                      .shiny-output-error-validation {
                      color: blue;
                      font-size: large;
                      }
                      "))
      ),
    navbarPage("NGS data",
               tabPanel("Runs",
                        sidebarLayout(
                          sidebarPanel(
                            helpText("Select options"),
                            dateRangeInput("sliderData",
                                           "Date to consider",
                                           start = Sys.Date()-90,
                                           end = NULL,
                                           min = NULL,
                                           max = NULL,
                                           format = "dd/mm/yyyy",
                                           startview = "month",
                                           weekstart = 1,
                                           language = "en",
                                           separator = " to ",
                                           width = 200
                            ),
                            checkboxGroupInput("sequencer", "Sequencer", sequencers, selected = sequencers[1:3])
                          ),
                          mainPanel(
                            tabsetPanel(
                              tabPanel("Percentage \u2265 Q30", 
                                       fluidRow(plotOutput("Run_Q30", width = "1250px", height = "750px", dblclick = "plot1_dblclick", brush = brushOpts(id = "plot_brush", resetOnNew = TRUE))),
                                       fluidRow(DT::dataTableOutput("plot_brushed1"))
                              ),
                              tabPanel("Mean Quality Score", 
                                       fluidRow(plotOutput("Run_MQS", width = "1250px", height = "750px", dblclick = "plot1_dblclick", brush = brushOpts(id = "plot_brush", resetOnNew = TRUE))),
                                       fluidRow(DT::dataTableOutput("plot_brushed2"))
                              ),
                              tabPanel("Percentage Cluster Pass Filter", 
                                       fluidRow(plotOutput("Run_PF", width = "1250px", height = "750px", dblclick = "plot1_dblclick", brush = brushOpts(id = "plot_brush", resetOnNew = TRUE))),
                                       fluidRow(DT::dataTableOutput("plot_brushed3"))
                              )
                            )
                          )
                        )
               ),
               tabPanel("Sample",
                        sidebarLayout(
                          sidebarPanel(
                            helpText("Select options"),
                            dateRangeInput("sliderData2",
                                           "Date to consider",
                                           start = Sys.Date()-90,
                                           end = NULL,
                                           min = NULL,
                                           max = NULL,
                                           format = "dd/mm/yyyy",
                                           startview = "month",
                                           weekstart = 1,
                                           language = "en",
                                           separator = " to ",
                                           width = 200
                            ),
                            checkboxGroupInput("sequencer1", "Sequencer", sequencers_processed, selected = sequencers_processed[1:3]),
                            selectInput("datatype", "Run or Sample", type, selected = type[1]),
                            checkboxGroupInput("methode", "Exomes or Genepanels", methode, selected = methode[1:2])
                          ),
                          mainPanel(
                            tabsetPanel(
                              tabPanel("Percentage AT Dropout", 
                                       fluidRow(plotOutput("Sample_ATdrop", width = "1250px", height = "750px", dblclick = "plot2_dblclick", brush = brushOpts(id = "plot_brush1", resetOnNew = TRUE))),
                                       fluidRow(DT::dataTableOutput("plot_brush_sample1"))
                              ),
                              tabPanel("Percentage Target bases 20X", 
                                       fluidRow(plotOutput("Perc_20X", width = "1250px", height = "750px", dblclick = "plot2_dblclick", brush = brushOpts(id = "plot_brush1", resetOnNew = TRUE))),
                                       fluidRow(DT::dataTableOutput("plot_brush_sample2"))
                              ),
                              tabPanel("Percentage Duplication", 
                                       fluidRow(plotOutput("Perc_dup", width = "1250px", height = "750px", dblclick = "plot2_dblclick", brush = brushOpts(id = "plot_brush1", resetOnNew = TRUE))),
                                       fluidRow(DT::dataTableOutput("plot_brush_sample3"))
                              )
                            )
                          )
                        )
               ),
               tabPanel("Combi",
                        sidebarLayout(                   
                          sidebarPanel(
                            helpText("Select options"),
                            dateRangeInput("sliderData3",
                                           "Date to consider",
                                           start = Sys.Date()-90,
                                           end = NULL,
                                           min = NULL,
                                           max = NULL,
                                           format = "dd/mm/yyyy",
                                           startview = "month",
                                           weekstart = 1,
                                           language = "en",
                                           separator = " to ",
                                           width = 200
                            ),
                            checkboxGroupInput("sequencer2", "Sequencer", sequencers, selected = sequencers[1:3])
                          ),
                          mainPanel(
                            tabsetPanel(
                              tabPanel("Pass Filter + Q30", 
                                       fluidRow(plotOutput("PF_Q30", width = "1250px", height = "750px", dblclick = "plot3_dblclick", brush = brushOpts(id = "plot_brush2", resetOnNew = TRUE))),
                                       fluidRow(DT::dataTableOutput("plot_brush_combi1"))
                              ),
                              tabPanel("Mean Quality Score + Q30", 
                                       fluidRow(plotOutput("MQS_Q30", width = "1250px", height = "750px", dblclick = "plot3_dblclick", brush = brushOpts(id = "plot_brush2", resetOnNew = TRUE))),
                                       fluidRow(DT::dataTableOutput("plot_brush_combi2"))
                              )
                              
                            )
                          )
                        )
               ),
               tabPanel("Sample Lane Tabel",
                        sidebarLayout(
                          sidebarPanel(
                            helpText("Select columns"),
                            conditionalPanel(
                              'input.dataset === "Sample"',
                              checkboxGroupInput("colsample", "Columns", columns_sample, selected = columns_sample[1:length(columns_sample)])
                            ),
                            conditionalPanel(
                              'input.dataset === "Processed"',
                              checkboxGroupInput("colprocessed", "Columns", columns_processed, selected = columns_processed[1:length(columns_processed)])
                            )
                          ),
                          mainPanel(
                            tabsetPanel(
                              id = 'dataset',
                              tabPanel("Sample", DT::dataTableOutput("sample_table")),
                              tabPanel("Processed", DT::dataTableOutput("processed_table"))
                            )
                          )
                        )
               ),
               tabPanel("Lane",
                        sidebarLayout(
                          sidebarPanel(
                            helpText("Select Options"),
                            dateRangeInput("sliderData4",
                                           "Date to consider",
                                           start = Sys.Date()-90,
                                           end = NULL,
                                           min = NULL,
                                           max = NULL,
                                           format = "dd/mm/yyyy",
                                           startview = "month",
                                           weekstart = 1,
                                           language = "en",
                                           separator = " to ",
                                           width = 200
                            ),
                            checkboxGroupInput("sequencer3", "Sequencer", sequencers_run, selected = sequencers_run[1:3]),
                            checkboxGroupInput("lane", "Lanes", lanes, selected = lanes[1:4])
                          ),
                          mainPanel(
                            tabsetPanel(
                              tabPanel("Lane Q30", plotOutput("Lane_Q30", width = "1250px", height = "750px", dblclick = "plot4_dblclick", brush = brushOpts(id = "plot_brush3", resetOnNew = TRUE))),
                              tabPanel("Boxplot Lane Q30",plotOutput("Box_Lane_Q30", width = "1250px", height = "750px", dblclick = "plot4_dblclick", brush = brushOpts(id = "plot_brush3", resetOnNew = TRUE)))
                            )
                          )
                        )
               )
    )
      )
    )