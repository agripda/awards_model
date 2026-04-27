library(shiny)
library(bslib)
library(tidyverse)
library(solitude)    # Isolation Forest in R
library(randomForest) # For Risk Scoring
library(plotly)
library(lubridate)
library(forest)

# ==========================================
# 1. Generate Mock FWO Data
# ==========================================
set.seed(42)
n <- 200
mock_data <- tibble(
  business_id = paste0("BUS-", 1:n),
  industry = sample(c("Hospitality", "Retail", "Construction", "Cleaning"), n, replace = TRUE),
  emp_count = rpois(n, 20),
  complaints = rpois(n, 1.5),
  avg_daily_hrs = rnorm(n, 7.6, 0.4),
  std_dev_hrs = rnorm(n, 0.8, 0.3),
  past_breach = sample(c(0, 1), n, replace = TRUE, prob = c(0.8, 0.2))
)

# Artificially insert anomalies – “Too Perfect” records
anomalies <- tibble(
  business_id = c("BUS-991", "BUS-992"),
  industry = c("Hospitality", "Cleaning"),
  emp_count = c(12, 8),
  complaints = c(4, 6),
  avg_daily_hrs = c(7.6, 7.6), # suspiciously exact hours
  std_dev_hrs = c(0.01, 0.02), # almost no variance (possible manipulation)
  past_breach = c(1, 1)
)
mock_data <- bind_rows(mock_data, anomalies)

# ==========================================
# 2. UI Definition
# ==========================================
ui <- page_navbar(
  title = "FWO Analytics: Investigation Prioritization Tool",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  
  nav_panel("Risk Scoring",
    layout_sidebar(
      sidebar = sidebar(
        selectInput("ind_filter", "Select Industry:", choices = c("All", unique(mock_data$industry))),
        sliderInput("risk_threshold", "Risk Score Threshold:", 0, 1, 0.5),
        hr(),
        p("This model predicts breach probability based on past breach history and complaint frequency.")
      ),
      card(
        card_header("High-Risk Business Prioritization"),
        plotlyOutput("risk_plot")
      ),
      card(
        card_header("Investigation Priority List"),
        tableOutput("risk_table")
      )
    )
  ),
  
  nav_panel("Anomaly Detection",
    layout_sidebar(
      sidebar = sidebar(
        helpText("Uses Isolation Forest to detect businesses with suspiciously manipulated timesheet patterns."),
        actionButton("run_anomaly", "Run Detection", class = "btn-primary")
      ),
      card(
        card_header("Anomaly Analysis: 'Too Perfect' Records"),
        plotlyOutput("anomaly_plot")
      )
    )
  )
)

# ==========================================
# 3. Server Definition
# ==========================================
server <- function(input, output, session) {
  
  # A. Risk Scoring Model (Random Forest)
  risk_model <- randomForest(as.factor(past_breach) ~ industry + emp_count + complaints, data = mock_data)
  
  scored_data <- reactive({
    data <- mock_data
    # Calculate breach probability
    data$risk_score <- predict(risk_model, data, type = "prob")[,2]
    
    if (input$ind_filter != "All") {
      data <- data %>% filter(industry == input$ind_filter)
    }
    data
  })
  
  # B. Anomaly Detection Model (Isolation Forest)
  anomaly_data <- eventReactive(input$run_anomaly, {
    # Train Isolation Forest (based on hour variability)
    iso <- forest$new(data = mock_data %>% select(avg_daily_hrs, std_dev_hrs))
    mock_data$anomaly_score <- iso$predict(mock_data %>% select(avg_daily_hrs, std_dev_hrs))$anomaly_score
    
    # Top 5% considered anomalies
    threshold <- quantile(mock_data$anomaly_score, 0.95)
    mock_data$is_anomaly <- if_else(mock_data$anomaly_score >= threshold, "Anomaly", "Normal")
    mock_data
  })

  # C. Visualization Outputs
  output$risk_plot <- renderPlotly({
    p <- ggplot(scored_data(), aes(x = complaints, y = risk_score, color = industry, text = business_id)) +
      geom_point(size = 3, alpha = 0.7) +
      geom_hline(yintercept = input$risk_threshold, linetype = "dashed", color = "red") +
      theme_minimal() +
      labs(y = "Breach Probability (Risk Score)", x = "Number of Complaints")
    
    ggplotly(p)
  })
  
  output$risk_table <- renderTable({
    scored_data() %>%
      filter(risk_score >= input$risk_threshold) %>%
      arrange(desc(risk_score)) %>%
      select(business_id, industry, complaints, risk_score) %>%
      head(10)
  })
  
  output$anomaly_plot <- renderPlotly({
    req(anomaly_data())
    p <- ggplot(anomaly_data(), aes(x = avg_daily_hrs, y = std_dev_hrs, color = is_anomaly, text = business_id)) +
      geom_point(size = 3) +
      scale_color_manual(values = c("Anomaly" = "red", "Normal" = "grey")) +
      theme_minimal() +
      labs(title = "Detection of Artificial Payroll Patterns",
           x = "Average Daily Hours", y = "Volatility (Std Dev of Hours)")
    
    ggplotly(p)
  })
}

shinyApp(ui, server)
