library(shiny)
library(httr2)


api_base_url <- Sys.getenv(
  "COMPLETION_RISK_API_URL",
  unset = "http://127.0.0.1:8001"
)


# ============================================================
# API helpers
# ============================================================

check_api_health <- function() {
  tryCatch(
    {
      response <- request(
        paste0(api_base_url, "/health")
      ) |>
        req_timeout(3) |>
        req_error(
          is_error = function(response) {
            FALSE
          }
        ) |>
        req_perform()

      body <- resp_body_json(
        response,
        simplifyVector = TRUE
      )

      list(
        success = resp_status(response) == 200,
        status = resp_status(response),
        body = body,
        error = NULL
      )
    },
    error = function(error) {
      message(
        "API health-check error: ",
        conditionMessage(error)
      )

      list(
        success = FALSE,
        status = NULL,
        body = NULL,
        error = conditionMessage(error)
      )
    }
  )
}


request_prediction <- function(payload) {
  tryCatch(
    {
      response <- request(
        paste0(api_base_url, "/predict")
      ) |>
        req_body_json(payload) |>
        req_timeout(5) |>
        req_error(
          is_error = function(response) {
            FALSE
          }
        ) |>
        req_perform()

      body <- resp_body_json(
        response,
        simplifyVector = TRUE
      )

      list(
        success = resp_status(response) == 200,
        status = resp_status(response),
        body = body,
        error = NULL
      )
    },
    error = function(error) {
      message(
        "Prediction request error: ",
        conditionMessage(error)
      )

      list(
        success = FALSE,
        status = NULL,
        body = NULL,
        error = conditionMessage(error)
      )
    }
  )
}


extract_error_message <- function(result) {
  if (
    !is.null(result$body) &&
    !is.null(result$body$error)
  ) {
    return(
      as.character(result$body$error)
    )
  }

  if (!is.null(result$error)) {
    return(
      as.character(result$error)
    )
  }

  "An unexpected error occurred."
}


# ============================================================
# User interface
# ============================================================

ui <- fluidPage(
  titlePanel(
    "Completion Risk Prediction"
  ),

  tags$div(
    style = paste(
      "padding: 12px;",
      "margin-bottom: 20px;",
      "background-color: #eff6ff;",
      "border-left: 4px solid #2563eb;"
    ),

    tags$strong(
      "Observation window: "
    ),

    paste(
      "All input values must represent learner activity",
      "accumulated during the first 10 course days."
    )
  ),

  sidebarLayout(
    sidebarPanel(
      numericInput(
        "user_id",
        "User ID",
        value = 1002,
        min = 1,
        step = 1
      ),

      numericInput(
        "n_passed_all",
        "Passed steps",
        value = 3,
        min = 0,
        max = 198,
        step = 1
      ),

      numericInput(
        "n_viewed_all",
        "Viewed steps",
        value = 15,
        min = 0,
        step = 1
      ),

      numericInput(
        "n_started_practical",
        "Started practical steps",
        value = 2,
        min = 0,
        step = 1
      ),

      numericInput(
        "n_passed_practical",
        "Passed practical steps",
        value = 1,
        min = 0,
        max = 76,
        step = 1
      ),

      numericInput(
        "n_submissions",
        "Submissions",
        value = 4,
        min = 0,
        step = 1
      ),

      numericInput(
        "submission_correct_rate",
        "Correct submission rate",
        value = 0.25,
        min = 0,
        max = 1,
        step = 0.01
      ),

      numericInput(
        "active_days",
        "Active days",
        value = 3,
        min = 1,
        max = 10,
        step = 1
      ),

      numericInput(
        "days_since_last_action",
        "Days since last action",
        value = 6,
        min = 0,
        max = 9,
        step = 1
      ),

      numericInput(
        "score_per_active_day",
        "Score per active day",
        value = 1,
        min = 0,
        max = 88,
        step = 0.01
      ),

      numericInput(
        "steps_per_active_day",
        "Steps per active day",
        value = 5,
        min = 0,
        max = 198,
        step = 0.01
      ),

      actionButton(
        "predict",
        "Predict completion risk",
        class = "btn-primary"
      )
    ),

    mainPanel(
      actionButton(
        "check_api",
        "Reconnect API"
      ),

      tags$hr(),

      uiOutput(
        "api_status"
      ),

      tags$hr(),

      uiOutput(
        "prediction_summary"
      )
    )
  )
)


# ============================================================
# Server logic
# ============================================================

server <- function(
  input,
  output,
  session
) {
  health_result <- eventReactive(
    input$check_api,
    {
      check_api_health()
    },
    ignoreNULL = FALSE
  )


  prediction_result <- eventReactive(
    input$predict,
    {
      payload <- list(
        user_id =
          as.numeric(input$user_id),

        n_passed_all =
          as.numeric(input$n_passed_all),

        n_viewed_all =
          as.numeric(input$n_viewed_all),

        n_started_practical =
          as.numeric(input$n_started_practical),

        n_passed_practical =
          as.numeric(input$n_passed_practical),

        n_submissions =
          as.numeric(input$n_submissions),

        submission_correct_rate =
          as.numeric(input$submission_correct_rate),

        active_days =
          as.numeric(input$active_days),

        days_since_last_action =
          as.numeric(input$days_since_last_action),

        score_per_active_day =
          as.numeric(input$score_per_active_day),

        steps_per_active_day =
          as.numeric(input$steps_per_active_day)
      )

      request_prediction(
        payload
      )
    }
  )


  output$api_status <- renderUI({
    result <- health_result()

    if (isTRUE(result$success)) {
      tags$div(
        style = paste(
          "color: #15803d;",
          "font-weight: 600;"
        ),

        "API connected"
      )
    } else {
      tags$div(
        style = paste(
          "padding: 10px 12px;",
          "border-left: 4px solid #b91c1c;",
          "background-color: #fef2f2;",
          "color: #b91c1c;"
        ),

        tags$strong(
          "API unavailable: "
        ),

        extract_error_message(result)
      )
    }
  })


  output$prediction_summary <- renderUI({
    result <- prediction_result()

    if (isTRUE(result$success)) {
      completion_risk <- as.numeric(
        result$body$completion_risk
      )

      predicted_status <-
        result$body$predicted_completion_status

      status_label <- if (
        identical(
          predicted_status,
          "Predicted_Completed"
        )
      ) {
        "Predicted to complete"
      } else {
        "Predicted not to complete"
      }

      status_color <- if (
        identical(
          predicted_status,
          "Predicted_Completed"
        )
      ) {
        "#15803d"
      } else {
        "#b91c1c"
      }

      tagList(
        tags$h3(
          paste(
            "Learner",
            result$body$user_id
          )
        ),

        tags$div(
          style = paste(
            "display: inline-block;",
            "padding: 6px 12px;",
            "margin-bottom: 16px;",
            "border-radius: 6px;",
            "color: white;",
            "font-weight: 700;",
            paste0(
              "background-color: ",
              status_color,
              ";"
            )
          ),

          status_label
        ),

        tags$p(
          style = "font-size: 18px;",

          tags$strong(
            "Non-completion risk: "
          ),

          sprintf(
            "%.1f%%",
            completion_risk * 100
          )
        ),

        tags$p(
          style = "color: #4b5563;",

          paste(
            "This prediction supports learner prioritisation",
            "and does not guarantee an outcome."
          )
        )
      )
    } else {
      tags$div(
        style = paste(
          "padding: 10px 12px;",
          "border-left: 4px solid #b91c1c;",
          "background-color: #fef2f2;",
          "color: #b91c1c;"
        ),

        tags$strong(
          "Prediction failed: "
        ),

        extract_error_message(result)
      )
    }
  })
}


shinyApp(
  ui = ui,
  server = server
)