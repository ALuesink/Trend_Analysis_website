library(shiny)
library(shinythemes)

sequencers <- c("hiseq_umc01", "nextseq_umc01", "nextseq_umc02")
lanes <- c(1,2,3,4)
columns_Processed <- c("Sample_name","Total_number_of_reads","Percentage_reads_mapped","Total_reads","PF_reads","PF_unique_reads","PCT_PF_reads","PCT_PF_UQ_reads","PCT_UQ_reads_aligned",'PCT_PF_UQ_reads_aligned',"PF_UQ_bases_aligned","On_bait_bases","Near_bait_bases","Off_bait_bases","On_target_bases","PCT_selected_bases","PCT_off_bait","On_bait_vs_selected","Mean_bait_coverage","Mean_target_coverage","PCT_usable_bases_on_bait","PCT_usable_bases_on_target","Fold_enrichment","Zero_CVG_targets_PCT","Fold_80_base_penalty","PCT_target_bases_2X","PCT_target_bases_10X","PCT_target_bases_20X","PCT_target_bases_30X","PCT_target_bases_40X","PCT_target_bases_50X","PCT_target_bases_100X","HS_library_size","HS_penalty_10X","HS_penalty_20X","HS_penalty_30X","HS_penalty_40X","HS_penalty_50X","HS_penalty_100X","AT_dropout","GC_dropout",'Duplication',"Number_variants","PCT_dbSNP_variants","PCT_PASS_variants","Run","Sequencer")
columns_lane <- c("Lane","PCT_of_lane","PCT_perfect_barcode","PCT_one_mismatch_barcode","Yield_Mbases",'PCT_PF_Clusters',"PCT_Q30_bases","Mean_Quality_Score","Run","Sequencer")
columns_sample <- c("Lane","Project","Sample_name","Barcode_sequence","PF_Clusters","PCT_of_lane","PCT_perfect_barcode","PCT_one_mismatch_barcode","Yield_Mbases","PCT_PF_Clusters","PCT_Q30_bases","Mean_Quality_Score","Run","Sequencer")

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
                             width = 200,
                             format = "dd-mm-yyyy"
              ),
              checkboxGroupInput("sequencer1", "Sequencers", sequencers, selected = sequencers[1:3]),
              width = 3
            ),
            mainPanel(
              tabsetPanel(
                tabPanel("Percentage \u2265 Q30",
                         fluidRow(plotOutput("Run_Q30", width = "1250px", height = "750px", dblclick = "run_dblclick", brush = brushOpts(id = "run_brush", resetOnNew = TRUE))),
                         fluidRow(DT::dataTableOutput("Run_Q30_brushed"))
                
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
                            width = 200,
                            format = "dd-mm-yyyy"
             ),
             checkboxGroupInput("sequencer2", "Sequencers", sequencers, selected = sequencers[1:3]),
             checkboxGroupInput("lanes", "Lanes", lanes, selected = lanes[1:4]),
             width = 3
              ),
           mainPanel(
             tabsetPanel(
               tabPanel("Percentage Q30 per Lane",
                        plotOutput("Lane_Q30_line", width = "1250px", height = "750px", dblclick = "lane_dblclick", brush = brushOpts(id = "lane_brush", resetOnNew = TRUE))
                ),
               tabPanel("Mean Quality Score per Lane",
                        plotOutput("Lane_MQS_line", width = "1250px", height = "750px", dblclick = "lane_dblclick", brush = brushOpts(id = "lane_brush", resetOnNew = TRUE))
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
                           width = 200
            ),
            checkboxGroupInput("sequencer3", "Sequencers", sequencers, selected = sequencers[1:3]),
            downloadButton("download_plot3", "Download Plot"),
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
              checkboxGroupInput("columns_sample", "Columns", columns_sample, selected = columns_sample[1:length(columns_sample)])
            ),
            conditionalPanel(
              'input.dataset == "Lane Sequencer data"',
              downloadButton("down_lane_seq", "Download data"),
              checkboxGroupInput("columns_lane", "Columns", columns_lane, selected = columns_lane[1:length(columns_lane)])
            ),
            conditionalPanel(
              'input.dataset == "Processed data"',              
              downloadButton("down_sample_proc", "Download data"),
              checkboxGroupInput("columns_processed", "Columns", columns_Processed, selected = columns_Processed[1:length(columns_Processed)])
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