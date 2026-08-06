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


request_batch_prediction <- function(payload) {
  tryCatch(
    {
      response <- request(
        paste0(api_base_url, "/predict-batch")
      ) |>
        req_body_json(payload) |>
        req_timeout(15) |>
        req_error(
          is_error = function(response) {
            FALSE
          }
        ) |>
        req_perform()

      body <- resp_body_json(
        response,
        simplifyVector = FALSE
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
        "Batch prediction request error: ",
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
# Data-conversion helpers
# ============================================================

data_frame_to_records <- function(data) {
  if (
    !is.data.frame(data) ||
    nrow(data) == 0L
  ) {
    return(
      list()
    )
  }

  lapply(
    seq_len(nrow(data)),
    function(row_number) {
      row <- data[
        row_number,
        ,
        drop = FALSE
      ]

      lapply(
        row,
        function(column) {
          column[[1]]
        }
      )
    }
  )
}


records_to_data_frame <- function(records) {
  if (
    is.null(records) ||
    length(records) == 0L
  ) {
    return(
      data.frame()
    )
  }

  rows <- lapply(
    records,
    function(record) {
      as.data.frame(
        record,
        stringsAsFactors = FALSE
      )
    }
  )

  result <- do.call(
    rbind,
    rows
  )

  rownames(result) <- NULL

  result
}


format_predictions_for_display <- function(predictions) {
  if (nrow(predictions) == 0L) {
    return(predictions)
  }

  display <- predictions[
    ,
    intersect(
      c(
        "user_id",
        "completion_probability",
        "completion_risk",
        "predicted_completion_status"
      ),
      names(predictions)
    ),
    drop = FALSE
  ]

  display$completion_probability <- sprintf(
    "%.1f%%",
    as.numeric(
      display$completion_probability
    ) * 100
  )

  display$completion_risk <- sprintf(
    "%.1f%%",
    as.numeric(
      display$completion_risk
    ) * 100
  )

  display$predicted_completion_status <- ifelse(
    display$predicted_completion_status ==
      "Predicted_Completed",
    "Predicted to complete",
    "Predicted not to complete"
  )

  names(display) <- c(
    "User ID",
    "Completion probability",
    "Non-completion risk",
    "Prediction"
  )

  display
}


format_queue_for_display <- function(queue) {
  if (nrow(queue) == 0L) {
    return(queue)
  }

  display <- queue[
    ,
    intersect(
      c(
        "user_id",
        "risk_rank",
        "completion_risk",
        "predicted_completion_status"
      ),
      names(queue)
    ),
    drop = FALSE
  ]

  display$completion_risk <- sprintf(
    "%.1f%%",
    as.numeric(
      display$completion_risk
    ) * 100
  )

  display$predicted_completion_status <- ifelse(
    display$predicted_completion_status ==
      "Predicted_Completed",
    "Predicted to complete",
    "Predicted not to complete"
  )

  names(display) <- c(
    "User ID",
    "Risk rank",
    "Non-completion risk",
    "Prediction"
  )

  display
}


# ============================================================
# User interface
# ============================================================

ui <- fluidPage(
  tags$head(
    tags$style(
      HTML(
        "
        .download-button {
          margin-right: 8px;
          margin-bottom: 12px;
        }

        .status-success {
          color: #15803d;
          font-weight: 600;
        }

        .error-box {
          padding: 10px 12px;
          border-left: 4px solid #b91c1c;
          background-color: #fef2f2;
          color: #b91c1c;
          margin-bottom: 15px;
        }

        .success-box {
          padding: 10px 12px;
          border-left: 4px solid #15803d;
          background-color: #f0fdf4;
          color: #166534;
          margin-bottom: 15px;
        }

        .info-box {
          padding: 12px;
          margin-bottom: 20px;
          background-color: #eff6ff;
          border-left: 4px solid #2563eb;
        }
        "
      )
    )
  ),

  titlePanel(
    "Completion Risk Prediction"
  ),

  tags$div(
    class = "info-box",

    tags$strong(
      "Observation window: "
    ),

    paste(
      "All input values must represent learner activity",
      "accumulated during the first 10 course days."
    )
  ),

  fluidRow(
    column(
      width = 12,

      actionButton(
        "check_api",
        "Reconnect API"
      ),

      tags$span(
        style = "margin-left: 12px;",

        uiOutput(
          "api_status",
          inline = TRUE
        )
      )
    )
  ),

  tags$hr(),

  tabsetPanel(
    id = "prediction_mode",

    # ==========================================================
    # Single learner tab
    # ==========================================================

    tabPanel(
      "Single Learner",

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
          uiOutput(
            "prediction_summary"
          )
        )
      )
    ),

    # ==========================================================
    # Batch CSV tab
    # ==========================================================

    tabPanel(
      "Batch CSV",

      sidebarLayout(
        sidebarPanel(
          fileInput(
            "batch_file",
            "Upload learner CSV",
            accept = c(
              ".csv",
              "text/csv",
              "text/comma-separated-values"
            )
          ),

          numericInput(
            "batch_min_risk",
            "Minimum non-completion risk",
            value = 0.5,
            min = 0,
            max = 1,
            step = 0.05
          ),

          numericInput(
            "batch_top_n",
            "Maximum learners in queue",
            value = 10,
            min = 1,
            step = 1
          ),

          actionButton(
            "score_batch",
            "Score uploaded learners",
            class = "btn-primary"
          )
        ),

        mainPanel(
          uiOutput(
            "batch_file_status"
          ),

          tags$h4(
            "CSV preview"
          ),

          tableOutput(
            "batch_preview"
          ),

          tags$hr(),

          uiOutput(
            "batch_summary"
          ),

          uiOutput(
            "batch_download_buttons"
          ),

          tags$h4(
            "Retention queue"
          ),

          tableOutput(
            "retention_queue_table"
          ),

          tags$h4(
            "All predictions"
          ),

          tableOutput(
            "batch_predictions_table"
          )
        )
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
  # ----------------------------------------------------------
  # API health
  # ----------------------------------------------------------

  health_result <- eventReactive(
    input$check_api,
    {
      check_api_health()
    },
    ignoreNULL = FALSE
  )


  output$api_status <- renderUI({
    result <- health_result()

    if (isTRUE(result$success)) {
      tags$span(
        class = "status-success",
        "API connected"
      )
    } else {
      tags$span(
        style = paste(
          "color: #b91c1c;",
          "font-weight: 600;"
        ),

        paste(
          "API unavailable:",
          extract_error_message(result)
        )
      )
    }
  })


  # ----------------------------------------------------------
  # Single-learner prediction
  # ----------------------------------------------------------

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
        class = "error-box",

        tags$strong(
          "Prediction failed: "
        ),

        extract_error_message(result)
      )
    }
  })


  # ----------------------------------------------------------
  # Uploaded CSV
  # ----------------------------------------------------------

  batch_file_result <- reactive({
    if (is.null(input$batch_file)) {
      return(
        list(
          success = FALSE,
          data = NULL,
          error = NULL
        )
      )
    }

    tryCatch(
      {
        batch_data <- read.csv(
          input$batch_file$datapath,
          stringsAsFactors = FALSE,
          check.names = FALSE
        )

        list(
          success = TRUE,
          data = batch_data,
          error = NULL
        )
      },
      error = function(error) {
        list(
          success = FALSE,
          data = NULL,
          error = conditionMessage(error)
        )
      }
    )
  })


  output$batch_file_status <- renderUI({
    result <- batch_file_result()

    if (is.null(input$batch_file)) {
      return(
        tags$p(
          style = "color: #4b5563;",

          paste(
            "Upload a CSV file containing one learner per row."
          )
        )
      )
    }

    if (!isTRUE(result$success)) {
      return(
        tags$div(
          class = "error-box",

          tags$strong(
            "CSV could not be read: "
          ),

          result$error
        )
      )
    }

    tags$div(
      class = "success-box",

      paste0(
        input$batch_file$name,
        " loaded successfully: ",
        nrow(result$data),
        " learner(s), ",
        ncol(result$data),
        " column(s)."
      )
    )
  })


  output$batch_preview <- renderTable(
    {
      result <- batch_file_result()

      req(
        isTRUE(result$success)
      )

      head(
        result$data,
        5
      )
    },
    striped = TRUE,
    bordered = TRUE,
    spacing = "s",
    rownames = FALSE
  )


  # ----------------------------------------------------------
  # Batch prediction
  # ----------------------------------------------------------

  batch_result <- reactiveVal(
    NULL
  )


  observeEvent(
    input$batch_file,
    {
      batch_result(
        NULL
      )
    },
    ignoreInit = TRUE
  )


  observeEvent(
    input$score_batch,
    {
      file_result <- batch_file_result()

      if (!isTRUE(file_result$success)) {
        error_message <- if (
          is.null(file_result$error)
        ) {
          "Please upload a valid CSV file first."
        } else {
          file_result$error
        }

        batch_result(
          list(
            success = FALSE,
            status = NULL,
            body = NULL,
            error = error_message
          )
        )

        return()
      }

      if (nrow(file_result$data) == 0L) {
        batch_result(
          list(
            success = FALSE,
            status = NULL,
            body = NULL,
            error = "The uploaded CSV file contains no learners."
          )
        )

        return()
      }

      payload <- list(
        learners =
          data_frame_to_records(
            file_result$data
          ),

        min_risk =
          as.numeric(
            input$batch_min_risk
          ),

        top_n =
          as.numeric(
            input$batch_top_n
          )
      )

      batch_result(
        request_batch_prediction(
          payload
        )
      )
    }
  )


  batch_predictions_data <- reactive({
    result <- batch_result()

    req(
      !is.null(result),
      isTRUE(result$success)
    )

    records_to_data_frame(
      result$body$predictions
    )
  })


  retention_queue_data <- reactive({
    result <- batch_result()

    req(
      !is.null(result),
      isTRUE(result$success)
    )

    records_to_data_frame(
      result$body$retention_queue
    )
  })


  output$batch_summary <- renderUI({
    result <- batch_result()

    if (is.null(result)) {
      return(NULL)
    }

    if (!isTRUE(result$success)) {
      return(
        tags$div(
          class = "error-box",

          tags$strong(
            "Batch prediction failed: "
          ),

          extract_error_message(result)
        )
      )
    }

    tags$div(
      class = "success-box",

      paste0(
        result$body$learner_count,
        " learner(s) scored. ",
        result$body$queue_count,
        " learner(s) added to the retention queue."
      )
    )
  })


  output$batch_download_buttons <- renderUI({
    result <- batch_result()

    req(
      !is.null(result),
      isTRUE(result$success)
    )

    tagList(
      downloadButton(
        "download_predictions",
        "Download all predictions",
        class = "download-button"
      ),

      downloadButton(
        "download_queue",
        "Download retention queue",
        class = "download-button"
      )
    )
  })


  output$retention_queue_table <- renderTable(
    {
      queue <- retention_queue_data()

      format_queue_for_display(
        queue
      )
    },
    striped = TRUE,
    bordered = TRUE,
    spacing = "s",
    rownames = FALSE
  )


  output$batch_predictions_table <- renderTable(
    {
      predictions <- batch_predictions_data()

      format_predictions_for_display(
        predictions
      )
    },
    striped = TRUE,
    bordered = TRUE,
    spacing = "s",
    rownames = FALSE
  )


  # ----------------------------------------------------------
  # CSV downloads
  # ----------------------------------------------------------

  output$download_predictions <- downloadHandler(
    filename = function() {
      paste0(
        "completion_risk_predictions_",
        Sys.Date(),
        ".csv"
      )
    },
    content = function(file) {
      write.csv(
        batch_predictions_data(),
        file,
        row.names = FALSE,
        na = ""
      )
    }
  )


  output$download_queue <- downloadHandler(
    filename = function() {
      paste0(
        "retention_queue_",
        Sys.Date(),
        ".csv"
      )
    },
    content = function(file) {
      write.csv(
        retention_queue_data(),
        file,
        row.names = FALSE,
        na = ""
      )
    }
  )
}


shinyApp(
  ui = ui,
  server = server
)


shinyApp(
  ui = ui,
  server = server
)