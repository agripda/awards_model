# Install and load required packages
# install.packages(c("shiny", "shinydashboard", "tidyverse", "lubridate", "plotly", "DT"))
library(shiny)
library(shinydashboard)
library(tidyverse)
library(lubridate)
library(plotly)
library(DT)

# ==========================================
# 1. Global Data and Engine
# ==========================================

# Dim Tables (Reference Information)
dim_awards <- tibble(
  award_id = "REST_2020",
  award_name = "Restaurant Industry Award 2020",
  ot_threshold = 8.0,
  break_threshold = 5.0,
  break_deduction = 0.5,
  daily_allowance = 5.0
)

dim_pay_rates <- tibble(
  award_id = rep("REST_2020", 3),
  level = rep("Level 2", 3),
  day_type = c("Weekday", "Saturday", "Sunday"),
  multiplier = c(1.0, 1.25, 1.5),
  base_rate = 25.21
)

dim_employees <- tibble(
  emp_id = "E001",
  name = "David Kim",
  award_id = "REST_2020",
  level = "Level 2"
)

# Compliance analysis engine
run_compliance_analysis <- function(fact, emp, awd, rates, user_base_rate) {
  # Apply user-modified base rate (What-if analysis)
  current_rates <- rates %>% mutate(base_rate = user_base_rate)
  
  fact %>%
    left_join(emp, by = "emp_id") %>%
    left_join(awd, by = "award_id") %>%
    mutate(
      day_name = weekdays(date),
      day_type = case_when(
        day_name == "Saturday" ~ "Saturday",
        day_name == "Sunday" ~ "Sunday",
        TRUE ~ "Weekday"
      )
    ) %>%
    left_join(current_rates, by = c("award_id", "level", "day_type")) %>%
    mutate(
      raw_hrs = as.numeric(hms(end_time) - hms(start_time)) / 3600,
      work_hrs = if_else(raw_hrs >= break_threshold, raw_hrs - break_deduction, raw_hrs),
      normal_hrs = pmin(work_hrs, ot_threshold),
      ot_hrs = pmax(0, work_hrs - ot_threshold),
      expected_pay = (normal_hrs * base_rate * multiplier) + 
                     (ot_hrs * base_rate * 1.5) + 
                     daily_allowance,
      underpayment = round(expected_pay - actual_paid, 2),
      status = if_else(underpayment > 0, "Underpaid", "Compliant")
    )
}

# ==========================================
# 2. UI Definition
# ==========================================
ui <- dashboardPage(
  dashboardHeader(title = "FWO Underpayment Tracker"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Detailed Data", tabName = "data", icon = icon("table"))
    ),
    hr(),
    h4(" [Award Settings]", style = "padding-left: 15px;"),
    numericInput("base_rate", "Base Rate ($/hr):", value = 25.21, step = 0.1),
    numericInput("ot_limit", "Daily OT Threshold:", value = 8.0, step = 0.5),
    helpText("Adjust rates to explore What-if scenarios.")
  ),
  
  dashboardBody(
    tabItems(
      # Tab 1: Visualization Dashboard
      tabItem(tabName = "dashboard",
        fluidRow(
          valueBoxOutput("total_underpaid_box", width = 4),
          valueBoxOutput("breach_count_box", width = 4),
          valueBoxOutput("max_gap_box", width = 4)
        ),
        fluidRow(
          box(title = "Actual vs Expected Pay by Date", status = "primary", solidHeader = TRUE, width = 8,
              plotlyOutput("pay_comparison_plot")),
          box(title = "Status Breakdown", status = "warning", solidHeader = TRUE, width = 4,
              plotlyOutput("status_pie_plot"))
        )
      ),
      
      # Tab 2: Detailed Data Table
      tabItem(tabName = "data",
        fluidRow(
          box(title = "Calculated Compliance Table", width = 12,
              DTOutput("full_table"))
        )
      )
    )
  )
)

# ==========================================
# 3. Server Definition
# ==========================================
server <- function(input, output) {
  
  # Reactive analysis execution
  processed_data <- reactive({
    # Initial fact data (reactive to user input)
    fact_data <- tibble(
      timesheet_id = 1:4,
      emp_id = "E001",
      date = as.Date(c("2024-05-01", "2024-05-02", "2024-05-04", "2024-05-05")),
      start_time = c("08:00:00", "09:00:00", "10:00:00", "11:00:00"),
      end_time = c("17:00:00", "20:00:00", "18:00:00", "16:00:00"),
      actual_paid = c(200.0, 250.0, 250.0, 150.0)
    )
    
    # Run analysis engine (reflect UI inputs)
    run_compliance_analysis(fact_data, dim_employees, dim_awards, dim_pay_rates, input$base_rate)
  })
  
  # KPI Boxes
  output$total_underpaid_box <- renderValueBox({
    total <- sum(processed_data()$underpayment[processed_data()$underpayment > 0])
    valueBox(paste0("$", round(total, 2)), "Total Underpayment", icon = icon("money-bill-wave"), color = "red")
  })
  
  output$breach_count_box <- renderValueBox({
    count <- sum(processed_data()$status == "Underpaid")
    valueBox(count, "Breach Incidents", icon = icon("exclamation-triangle"), color = "orange")
  })
  
  output$max_gap_box <- renderValueBox({
    max_gap <- max(processed_data()$underpayment)
    valueBox(paste0("$", max_gap), "Max Daily Gap", icon = icon("chart-line"), color = "purple")
  })
  
  # Visualization 1: Pay Comparison Chart
  output$pay_comparison_plot <- renderPlotly({
    p <- processed_data() %>%
      pivot_longer(cols = c(expected_pay, actual_paid), names_to = "type", values_to = "amount") %>%
      ggplot(aes(x = date, y = amount, fill = type)) +
      geom_bar(stat = "identity", position = "dodge") +
      theme_minimal() +
      labs(y = "Amount ($)", x = "Date")
    
    ggplotly(p)
  })
  
  # Visualization 2: Status Pie Chart
  output$status_pie_plot <- renderPlotly({
    df_pie <- processed_data() %>% count(status)
    plot_ly(df_pie, labels = ~status, values = ~n, type = 'pie', marker = list(colors = c('#28a745', '#dc3545')))
  })
  
  # Data Table Output
  output$full_table <- renderDT({
    datatable(processed_data(), options = list(pageLength = 5)) %>%
      formatStyle('status', color = styleEqual(c("Underpaid", "Compliant"), c('red', 'green')))
  })
}

# Run App
shinyApp(ui, server)
