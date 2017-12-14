library(shiny)
library(shinythemes)

sequencers <- c("hiseq_umc01", "nextseq_umc01", "nextseq_umc02", "novaseq_umc01")
lanes <- c(1,2,3,4)

shinyUI(
  fluidPage(theme = shinytheme("flatly"),
    tags$head(
      tags$style(HTML("
              .shiny-output-error-validation {
              color: red;
              font-size: large;
              }
              "))
    ),
    navbarPage("Trend-analyse NGS Data",
      navbarMenu("Sequencer data",
        tabPanel("Run",
          sidebarLayout(
            sidebarPanel(
              dateRangeInput("date_input1",
                             "Date to consider",
                             start = Sys.Date() - 90,
                             end = NULL,
                             startview = "month",
                             weekstart = 1,
                             language = "en",
                             separator = "to",
                             width = 250,
                             format = "dd-mm-yyyy"
              ),
              uiOutput("sequencer1"),
              width = 3
            ),
            mainPanel(
              tabsetPanel(
                tabPanel("Percentage \u2265 Q30",
                         fluidRow(plotOutput("Run_Q30", width = "1250px", height = "750px", dblclick = "run_dblclick", brush = brushOpts(id = "run_brush", resetOnNew = TRUE))),
                         fluidRow(DT::dataTableOutput("Run_Q30_brushed"))
                ),
                tabPanel("Percentage PF Clusters",
                         plotOutput("Run_PF", width = "1250px", height = "750px", dblclick = "run_dblclick", brush = brushOpts(id = "run_brush", resetOnNew = TRUE)),
                         fluidRow(DT::dataTableOutput("Run_PF_brushed"))
                ),
                tabPanel("Mean Quality Score",
                         fluidRow(plotOutput("Run_MQS", width = "1250px", height = "750px", dblclick = "run_dblclick", brush = brushOpts(id = "run_brush", resetOnNew = TRUE))),
                         fluidRow(DT::dataTableOutput("Run_MQS_brushed"))
                ),
                tabPanel("Percentage One Mismatch Barcode",
                         fluidRow(plotOutput("Run_Bar", width = "1250px", height = "750px", dblclick = "run_dblclick", brush = brushOpts(id = "run_brush", resetOnNew = TRUE))),
                         fluidRow(DT::dataTableOutput("Run_Bar_brushed"))
                ),
                tabPanel("Mean Quality Score & Q30",
                         plotOutput("MSQ_Q30", width = "1250px", height = "750px", dblclick = "run_dblclick", brush = brushOpts(id = "run_brush", resetOnNew = TRUE))
                )
              )
            )
          )
        ),
        tabPanel("Lane",
          sidebarLayout(
           sidebarPanel(
             dateRangeInput("date_input2",
                            "Date to consider",
                            start = Sys.Date() - 90,
                            end = NULL,
                            startview = "month",
                            weekstart = 1,
                            language = "en",
                            separator = "to",
                            width = 250,
                            format = "dd-mm-yyyy"
             ),
             uiOutput("sequencer2"),
             uiOutput("lanes"),
             width = 3
              ),
           mainPanel(
             tabsetPanel(
               tabPanel("Percentage Q30 per Lane",
                        fluidRow(plotOutput("Lane_Q30_line", width = "1250px", height = "750px", dblclick = "lane_dblclick", brush = brushOpts(id = "lane_brush", resetOnNew = TRUE))),
                        fluidRow(DT::dataTableOutput("Lane_Q30_brushed"))
                ),
               tabPanel("Mean Quality Score per Lane",
                        fluidRow(plotOutput("Lane_MQS_line", width = "1250px", height = "750px", dblclick = "lane_dblclick", brush = brushOpts(id = "lane_brush", resetOnNew = TRUE))),
                        fluidRow(DT::dataTableOutput("Lane_MQS_brushed"))
                )
              )
            )
          )
        )
      ),
      tabPanel("Processed data",
        sidebarLayout(
          sidebarPanel(
            dateRangeInput("date_input3",
                           "Date to consider",
                           start = Sys.Date() - 90,
                           end = NULL,
                           startview = "month",
                           weekstart = 1,
                           language = "en",
                           separator = "to",
                           width = 250,
                           format = "dd-mm-yyyy"
            ),
            uiOutput("sequencer3"),
            width = 3
          ),
          mainPanel(
            tabsetPanel(id = "tab_proc",
              tabPanel("Percentage Duplicates", value = "Proc_dup",
                       fluidRow(plotOutput("Proc_dup", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_dup_brushed"))
              ),
              tabPanel("Percentage Selected bases", value = "Proc_selected",
                       fluidRow(plotOutput("Proc_selected", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_selected_brushed"))
              ),
              tabPanel("Mean Targetcoverage", value = "Proc_MTC",
                       fluidRow(plotOutput("Proc_meantarget", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_meantarget_brushed"))
              ),
              tabPanel("Mean Baitcoverage", value = "Proc_MTC",
                       fluidRow(plotOutput("Proc_meanbait", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_meanbait_brushed"))
              ),
              tabPanel("Percentage Target bases 20X", value = "Proc_MTC",
                       fluidRow(plotOutput("Proc_target20X", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_target20X_brushed"))
              ),
              tabPanel("Percentage AT dropout", value = "Proc_MTC",
                       fluidRow(plotOutput("Proc_ATdrop", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_ATdrop_brushed"))
              ),
              tabPanel("Percentage GC dropout", value = "Proc_MTC",
                       fluidRow(plotOutput("Proc_GCdrop", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_GCdrop_brushed"))
              ),
              tabPanel("Number of variants", value = "Proc_MTC",
                       fluidRow(plotOutput("Proc_variants", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_variants_brushed"))
              ),
              tabPanel("Percentage dbSNP variants", value = "Proc_MTC",
                       fluidRow(plotOutput("Proc_dbSNP", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_dbSNP_brushed"))
              ),
              tabPanel("Percentage PASS variants", value = "Proc_MTC",
                       fluidRow(plotOutput("Proc_PASS", width = "1250px", height = "750px", dblclick = "proc_dblclick", brush = brushOpts(id = "proc_brush", resetOnNew = TRUE))),
                       fluidRow(DT::dataTableOutput("Proc_PASS_brushed"))
              )
            )
          )
        )
      ),
      tabPanel("Datatables",
        sidebarLayout(
          sidebarPanel(
            conditionalPanel(
              'input.dataset == "Sample Sequencer data"',
              downloadButton("down_sample_seq", "Download data"),
              uiOutput("Samp_columns")
            ),
            conditionalPanel(
              'input.dataset == "Lane Sequencer data"',
              downloadButton("down_lane_seq", "Download data"),
              uiOutput("Lane_columns")
            ),
            conditionalPanel(
              'input.dataset == "Processed data"',              
              downloadButton("down_sample_proc", "Download data"),
              uiOutput("Proc_columns")
            ),
            width = 3
          ),
          mainPanel(
            tabsetPanel(id = "dataset",
              tabPanel("Sample Sequencer data", DT::dataTableOutput("run_table")
              ),
              tabPanel("Lane Sequencer data", DT::dataTableOutput("lane_table")
              ),
              tabPanel("Processed data", DT::dataTableOutput("processed_table")
              )
            )
          )
        )
      )
    )
  )
)