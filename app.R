# 필요한 패키지 설치 및 로드
# install.packages(c("shiny", "shinydashboard", "tidyverse", "lubridate", "plotly", "DT"))
library(shiny)
library(shinydashboard)
library(tidyverse)
library(lubridate)
library(plotly)
library(DT)

# ==========================================
# 1. 고정 데이터 및 엔진 (Global)
# ==========================================

# Dim Tables (기준 정보)
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

# 분석 엔진 함수
run_compliance_analysis <- function(fact, emp, awd, rates, user_base_rate) {
  # 사용자가 UI에서 수정한 시급 반영 (What-if 분석 기능)
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
# 2. UI 정의
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
    helpText("Adjust rates to see What-if scenarios.")
  ),
  
  dashboardBody(
    tabItems(
      # Tab 1: 시각화 대시보드
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
      
      # Tab 2: 상세 데이터 테이블
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
# 3. Server 정의
# ==========================================
server <- function(input, output) {
  
  # 반응형 분석 실행
  processed_data <- reactive({
    # 초기 팩트 데이터 (사용자 입력에 반응)
    fact_data <- tibble(
      timesheet_id = 1:4,
      emp_id = "E001",
      date = as.Date(c("2024-05-01", "2024-05-02", "2024-05-04", "2024-05-05")),
      start_time = c("08:00:00", "09:00:00", "10:00:00", "11:00:00"),
      end_time = c("17:00:00", "20:00:00", "18:00:00", "16:00:00"),
      actual_paid = c(200.0, 250.0, 250.0, 150.0)
    )
    
    # 분석 엔진 실행 (UI 입력값 반영)
    run_compliance_analysis(fact_data, dim_employees, dim_awards, dim_pay_rates, input$base_rate)
  })
  
  # KPI 박스 출력
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
  
  # 시각화 1: 비교 차트
  output$pay_comparison_plot <- renderPlotly({
    p <- processed_data() %>%
      pivot_longer(cols = c(expected_pay, actual_paid), names_to = "type", values_to = "amount") %>%
      ggplot(aes(x = date, y = amount, fill = type)) +
      geom_bar(stat = "identity", position = "dodge") +
      theme_minimal() +
      labs(y = "Amount ($)", x = "Date")
    
    ggplotly(p)
  })
  
  # 시각화 2: 파이 차트
  output$status_pie_plot <- renderPlotly({
    df_pie <- processed_data() %>% count(status)
    plot_ly(df_pie, labels = ~status, values = ~n, type = 'pie', marker = list(colors = c('#28a745', '#dc3545')))
  })
  
  # 데이터 테이블 출력
  output$full_table <- renderDT({
    datatable(processed_data(), options = list(pageLength = 5)) %>%
      formatStyle('status', color = styleEqual(c("Underpaid", "Compliant"), c('red', 'green')))
  })
}

# 앱 실행
shinyApp(ui, server)
