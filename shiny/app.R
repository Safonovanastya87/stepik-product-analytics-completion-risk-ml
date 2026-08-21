library(shiny)
library(httr2)
library(readxl)
library(writexl)


# ============================================================
# Configuration
# ============================================================

api_base_url <- Sys.getenv(
  "COMPLETION_RISK_API_URL",
  unset = "http://127.0.0.1:8001"
)


required_batch_columns <- c(
  "user_id",
  "n_passed_all",
  "n_viewed_all",
  "n_started_practical",
  "n_passed_practical",
  "n_submissions",
  "submission_correct_rate",
  "active_days",
  "days_since_last_action",
  "score_per_active_day",
  "steps_per_active_day"
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
          is_error = function(response) FALSE
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
          is_error = function(response) FALSE
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
          is_error = function(response) FALSE
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

  if (!is.null(result$body)) {

    if (!is.null(result$body$error)) {

      return(
        paste(
          unlist(result$body$error),
          collapse = " "
        )
      )
    }


    if (!is.null(result$body$message)) {

      return(
        paste(
          unlist(result$body$message),
          collapse = " "
        )
      )
    }
  }


  if (!is.null(result$error)) {

    return(
      as.character(result$error)
    )
  }


  "An unexpected error occurred."
}


# ============================================================
# Validation helpers
# ============================================================

is_single_finite_number <- function(value) {

  length(value) == 1L &&
    is.numeric(value) &&
    !is.na(value) &&
    is.finite(value)
}


is_whole_number <- function(value) {

  is_single_finite_number(value) &&
    value == round(value)
}


validate_single_learner <- function(values) {

  errors <- list()


  # User ID
  if (
    !is_whole_number(values$user_id) ||
    values$user_id <= 0
  ) {

    errors$user_id <-
      "Enter a positive whole number."
  }


  # Overall course activity
  if (
    !is_whole_number(values$n_viewed_all) ||
    values$n_viewed_all < 0
  ) {

    errors$n_viewed_all <-
      "Viewed steps must be a non-negative whole number."
  }


  if (
    !is_whole_number(values$n_passed_all) ||
    values$n_passed_all < 0 ||
    values$n_passed_all > 198
  ) {

    errors$n_passed_all <-
      "Passed steps must be a whole number from 0 to 198."
  }


  if (
    !is_whole_number(values$active_days) ||
    values$active_days < 1 ||
    values$active_days > 10
  ) {

    errors$active_days <-
      "Active days must be a whole number from 1 to 10."
  }


  if (
    !is_whole_number(values$days_since_last_action) ||
    values$days_since_last_action < 0 ||
    values$days_since_last_action > 9
  ) {

    errors$days_since_last_action <-
      "Days since last action must be a whole number from 0 to 9."
  }


  # Practical engagement only
  if (
    !is_whole_number(values$n_started_practical) ||
    values$n_started_practical < 0
  ) {

    errors$n_started_practical <-
      "Started practical steps must be a non-negative whole number."
  }


  if (
    !is_whole_number(values$n_passed_practical) ||
    values$n_passed_practical < 0 ||
    values$n_passed_practical > 76
  ) {

    errors$n_passed_practical <-
      "Passed practical steps must be a whole number from 0 to 76."
  }


  if (
    !is_whole_number(values$n_submissions) ||
    values$n_submissions < 0
  ) {

    errors$n_submissions <-
      "Submissions must be a non-negative whole number."
  }


  if (
    !is_single_finite_number(
      values$submission_correct_rate
    ) ||
    values$submission_correct_rate < 0 ||
    values$submission_correct_rate > 1
  ) {

    errors$submission_correct_rate <-
      "Correct submission rate must be between 0 and 1."
  }


  # Activity intensity
  if (
    !is_single_finite_number(
      values$steps_per_active_day
    ) ||
    values$steps_per_active_day < 0 ||
    values$steps_per_active_day > 198
  ) {

    errors$steps_per_active_day <-
      "Steps per active day must be between 0 and 198."
  }


  if (
    !is_single_finite_number(
      values$score_per_active_day
    ) ||
    values$score_per_active_day < 0 ||
    values$score_per_active_day > 88
  ) {

    errors$score_per_active_day <-
      "Score per active day must be between 0 and 88."
  }


  # Cross-field validation
  if (
    is.null(errors$n_passed_practical) &&
    is.null(errors$n_passed_all) &&
    values$n_passed_practical >
      values$n_passed_all
  ) {

    errors$n_passed_practical <-
      "Passed practical steps cannot exceed total passed steps."
  }


  if (
    is.null(errors$n_passed_practical) &&
    is.null(errors$n_started_practical) &&
    values$n_passed_practical >
      values$n_started_practical
  ) {

    errors$n_passed_practical <-
      "Passed practical steps cannot exceed started practical steps."
  }


  if (
    is.null(errors$n_passed_practical) &&
    is.null(errors$n_submissions) &&
    values$n_passed_practical > 0 &&
    values$n_submissions == 0
  ) {

    errors$n_submissions <-
      "A passed practical step requires at least one submission."
  }


  if (
    is.null(errors$n_submissions) &&
    is.null(errors$n_started_practical) &&
    values$n_submissions > 0 &&
    values$n_started_practical == 0
  ) {

    errors$n_started_practical <-
      "Submissions require at least one started practical step."
  }


  errors
}


# ============================================================
# Batch validation
# ============================================================

validate_batch_rows <- function(data) {

  if (!is.data.frame(data)) {

    return(
      list(
        success = FALSE,
        error = "The uploaded file could not be read as tabular data."
      )
    )
  }


  if (nrow(data) == 0L) {

    return(
      list(
        success = FALSE,
        error = "The uploaded XLSX contains no learners."
      )
    )
  }


  missing_columns <- setdiff(
    required_batch_columns,
    names(data)
  )


  if (length(missing_columns) > 0L) {

    return(
      list(
        success = FALSE,

        error = paste0(
          "Missing required column(s): ",
          paste(
            missing_columns,
            collapse = ", "
          ),
          "."
        )
      )
    )
  }


  raw_data <- data[
    ,
    required_batch_columns,
    drop = FALSE
  ]


  numeric_data <- raw_data


  for (column_name in required_batch_columns) {

    numeric_data[[column_name]] <-
      suppressWarnings(
        as.numeric(
          trimws(
            as.character(
              raw_data[[column_name]]
            )
          )
        )
      )
  }


  row_errors <- vector(
    "list",
    nrow(numeric_data)
  )


  for (row_number in seq_len(nrow(numeric_data))) {

    values <- as.list(
      numeric_data[
        row_number,
        ,
        drop = FALSE
      ]
    )


    row_errors[[row_number]] <-
      validate_single_learner(values)
  }


  # Duplicate learner IDs
  valid_id <- vapply(
    numeric_data$user_id,
    function(value) {

      is_whole_number(value) &&
        value > 0
    },
    logical(1)
  )


  duplicate_id <- valid_id & (
    duplicated(numeric_data$user_id) |
      duplicated(
        numeric_data$user_id,
        fromLast = TRUE
      )
  )


  for (row_number in which(duplicate_id)) {

    row_errors[[row_number]]$duplicate_user_id <-
      "User ID is duplicated in this file."
  }


  invalid_rows <- which(
    lengths(row_errors) > 0L
  )


  valid_rows <- setdiff(
    seq_len(nrow(numeric_data)),
    invalid_rows
  )


  if (length(invalid_rows) == 0L) {

    validation_errors <- data.frame(
      `XLSX row` = integer(),
      `User ID` = character(),
      Problem = character(),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )

  } else {

    validation_errors <- do.call(
      rbind,

      lapply(
        invalid_rows,
        function(row_number) {

          raw_user_id <-
            raw_data$user_id[[row_number]]


          if (
            is.na(raw_user_id) ||
            trimws(
              as.character(raw_user_id)
            ) == ""
          ) {

            raw_user_id <- "—"
          }


          problems <- unname(
            unlist(
              row_errors[[row_number]]
            )
          )


          data.frame(
            `XLSX row` = row_number + 1L,
            `User ID` =
              as.character(raw_user_id),
            Problem = paste(
              unique(problems),
              collapse = " "
            ),
            check.names = FALSE,
            stringsAsFactors = FALSE
          )
        }
      )
    )
  }


  valid_data <- numeric_data[
    valid_rows,
    ,
    drop = FALSE
  ]


  rownames(valid_data) <- NULL


  list(
    success = TRUE,
    error = NULL,
    valid_data = valid_data,
    validation_errors = validation_errors,
    uploaded_count = nrow(data),
    valid_count = nrow(valid_data),
    rejected_count = nrow(validation_errors)
  )
}


# ============================================================
# Data conversion
# ============================================================

data_frame_to_records <- function(data) {

  if (
    !is.data.frame(data) ||
    nrow(data) == 0L
  ) {

    return(list())
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


# ============================================================
# Display helpers
# ============================================================

format_batch_input_preview <- function(data) {

  preview_order <- c(
    "user_id",
    "n_viewed_all",
    "n_passed_all",
    "active_days",
    "days_since_last_action",
    "n_started_practical",
    "n_passed_practical",
    "n_submissions",
    "submission_correct_rate",
    "steps_per_active_day",
    "score_per_active_day"
  )


  available_columns <- intersect(
    preview_order,
    names(data)
  )


  preview <- head(
    data[
      ,
      available_columns,
      drop = FALSE
    ],
    5
  )


  rename_map <- c(
    user_id = "User ID",
    n_viewed_all = "Viewed",
    n_passed_all = "Passed",
    active_days = "Active days",
    days_since_last_action = "Last action",
    n_started_practical = "Started practical",
    n_passed_practical = "Passed practical",
    n_submissions = "Submissions",
    submission_correct_rate = "Correct rate",
    steps_per_active_day = "Steps / active day",
    score_per_active_day = "Score / active day"
  )


  names(preview) <- unname(
    rename_map[
      names(preview)
    ]
  )


  preview
}

ensure_probability_columns <- function(data) {

  if (
    !is.data.frame(data) ||
    nrow(data) == 0L
  ) {

    return(data)
  }


  if (
    !"completion_probability" %in% names(data) &&
    "completion_risk" %in% names(data)
  ) {

    data$completion_probability <-
      1 - as.numeric(data$completion_risk)
  }


  if (
    !"completion_risk" %in% names(data) &&
    "completion_probability" %in% names(data)
  ) {

    data$completion_risk <-
      1 - as.numeric(data$completion_probability)
  }


  data
}


# Keep completion probability before non-completion risk,
# and always place non-completion risk at the far right.
order_probability_columns <- function(data) {

  if (!is.data.frame(data)) {
    return(data)
  }


  data <- ensure_probability_columns(data)


  ordinary_columns <- setdiff(
    names(data),
    c(
      "completion_probability",
      "completion_risk"
    )
  )


  ordered_columns <- c(
    ordinary_columns,
    intersect(
      "completion_probability",
      names(data)
    ),
    intersect(
      "completion_risk",
      names(data)
    )
  )


  data[
    ,
    ordered_columns,
    drop = FALSE
  ]
}


format_queue_for_display <- function(queue) {

  if (
    !is.data.frame(queue) ||
    nrow(queue) == 0L
  ) {

    return(
      data.frame()
    )
  }


  queue <- order_probability_columns(queue)


  display <- queue[
    ,
    intersect(
      c(
        "risk_rank",
        "user_id",
        "completion_probability",
        "completion_risk"
      ),
      names(queue)
    ),
    drop = FALSE
  ]


  probability_columns <- intersect(
    c(
      "completion_probability",
      "completion_risk"
    ),
    names(display)
  )


  for (column_name in probability_columns) {

    display[[column_name]] <- sprintf(
      "%.1f%%",
      as.numeric(
        display[[column_name]]
      ) * 100
    )
  }


  rename_map <- c(
    risk_rank = "Rank",
    user_id = "User ID",
    completion_probability =
      "Completion probability",
    completion_risk =
      "Non-completion probability"
  )


  names(display) <- unname(
    rename_map[
      names(display)
    ]
  )


  display
}


format_predictions_for_display <- function(predictions) {

  if (
    !is.data.frame(predictions) ||
    nrow(predictions) == 0L
  ) {

    return(
      data.frame()
    )
  }


  predictions <-
    order_probability_columns(
      predictions
    )


  display <- predictions[
    ,
    intersect(
      c(
        "user_id",
        "completion_probability",
        "completion_risk"
      ),
      names(predictions)
    ),
    drop = FALSE
  ]


  probability_columns <- intersect(
    c(
      "completion_probability",
      "completion_risk"
    ),
    names(display)
  )


  for (column_name in probability_columns) {

    display[[column_name]] <- sprintf(
      "%.1f%%",
      as.numeric(
        display[[column_name]]
      ) * 100
    )
  }


  rename_map <- c(
    user_id = "User ID",
    completion_probability =
      "Completion probability",
    completion_risk =
      "Non-completion probability"
  )


  names(display) <- unname(
    rename_map[
      names(display)
    ]
  )


  display
}

compact_table_ui <- function(
  data,
  extra_class = ""
) {

  if (
    !is.data.frame(data) ||
    nrow(data) == 0L
  ) {

    return(
      tags$div(
        class = "empty-table-message",
        "No rows to display."
      )
    )
  }


  header <- tags$tr(
    lapply(
      names(data),
      tags$th
    )
  )


  rows <- lapply(
    seq_len(nrow(data)),
    function(row_number) {

      tags$tr(
        lapply(
          data[
            row_number,
            ,
            drop = FALSE
          ],
          function(value) {

            tags$td(
              as.character(
                value[[1]]
              )
            )
          }
        )
      )
    }
  )


  tags$div(
    class = paste(
      "batch-table",
      extra_class
    ),

    tags$table(
      class = "table table-striped",

      tags$thead(
        header
      ),

      tags$tbody(
        rows
      )
    )
  )
}


queue_table_ui <- function(queue) {

  display <- format_queue_for_display(
    queue
  )


  if (nrow(display) == 0L) {

    return(
      tags$div(
        class = "empty-table-message",
        "No scored learners are available for prioritization."
      )
    )
  }


  tags$div(
    class = "queue-scroll",

    compact_table_ui(
      display,
      "queue-table"
    )
  )
}

# ============================================================
# Single learner UI helper
# ============================================================

learner_input_column <- function(
  width,
  id,
  label,
  value,
  step = 1
) {

  column(
    width = width,

    numericInput(
      inputId = id,
      label = label,
      value = value,
      step = step,
      width = "100%"
    ),

    uiOutput(
      paste0(
        id,
        "_error"
      )
    )
  )
}


# ============================================================
# UI
# ============================================================

ui <- fluidPage(

  tags$head(

    tags$title(
      "Learner Non-Completion Risk"
    ),


    tags$script(
      HTML(
        "
        Shiny.addCustomMessageHandler(
          'setInputError',
          function(message) {

            var element =
              document.getElementById(message.id);

            if (!element) {
              return;
            }

            if (message.hasError) {
              element.classList.add('input-invalid');
            } else {
              element.classList.remove('input-invalid');
            }
          }
        );

        Shiny.addCustomMessageHandler(
          'setBatchFileError',
          function(message) {

            var element =
              document.getElementById('batch_file_wrapper');

            if (!element) {
              return;
            }

            if (message.hasError) {
              element.classList.add(
                'batch-file-invalid'
              );
            } else {
              element.classList.remove(
                'batch-file-invalid'
              );
            }
          }
        );
        "
      )
    ),


    tags$style(
      HTML(
        "
        body {
          background: #f7f8fa;
          color: #1f2937;
          overflow-x: hidden;
        }

        .app-container {
          max-width: 1400px;
          margin: 0 auto;
          padding: 10px 18px 12px 18px;
        }

        .app-title {
          font-size: 32px;
          line-height: 1.1;
          font-weight: 650;
          margin-bottom: 3px;
        }

        .app-subtitle {
          font-size: 15px;
          color: #6b7280;
          margin-bottom: 10px;
        }

        .top-info-row {
          display: flex;
          align-items: center;
          gap: 14px;
          margin-bottom: 8px;
        }

        .observation-box {
          flex: 1;
          padding: 8px 13px;
          border-left: 4px solid #2563eb;
          background: #eff6ff;
          border-radius: 3px;
          font-size: 14px;
        }

        .api-panel {
          display: flex;
          align-items: center;
          gap: 10px;
          white-space: nowrap;
        }

        .api-status-wrapper {
          display: flex;
          align-items: center;
          gap: 6px;
        }

        .api-dot {
          width: 9px;
          height: 9px;
          display: inline-block;
          border-radius: 50%;
        }

        .api-connected {
          background: #16a34a;
        }

        .api-disconnected {
          background: #dc2626;
        }

        .api-text-success {
          color: #15803d;
          font-weight: 600;
        }

        .api-text-error {
          color: #b91c1c;
          font-weight: 600;
        }

        .reconnect-button {
          font-size: 13px;
          padding: 4px 9px;
        }

        .nav-tabs {
          margin-bottom: 10px;
        }

        .nav-tabs > li > a {
          padding: 8px 15px;
          color: #4b5563;
          font-weight: 500;
        }

        .nav-tabs > li.active > a,
        .nav-tabs > li.active > a:hover,
        .nav-tabs > li.active > a:focus {
          color: #1f2937;
          font-weight: 600;
        }

        .section-card {
          width: 100%;
          background: #ffffff;
          border: 1px solid #e5e7eb;
          border-radius: 10px;
          padding: 14px 20px;
          box-shadow: 0 1px 2px rgba(0,0,0,0.04);
          margin-bottom: 10px;
        }

        /* ====================================================
           Single Learner
           ==================================================== */

        .single-page-row {
          display: flex;
          align-items: stretch;
        }

        .single-page-row > div {
          display: flex;
        }

        .single-input-card {
          min-height: 395px;
        }

        .user-id-wrapper {
          max-width: 230px;
        }

        .feature-section {
          margin-top: 7px;
        }

        .feature-section-heading {
          font-size: 13px;
          font-weight: 700;
          color: #374151;
          text-transform: uppercase;
          letter-spacing: 0.055em;
          padding-bottom: 5px;
          margin-bottom: 7px;
          border-bottom: 1px solid #e5e7eb;
        }

        .compact-form .form-group {
          margin-bottom: 4px;
        }

        .compact-form .form-group label {
          font-size: 12.5px;
          font-weight: 600;
          color: #4b5563;
          margin-bottom: 3px;
          white-space: nowrap;
        }

        .compact-form .form-control {
          height: 33px;
          border-radius: 6px;
          border-color: #d1d5db;
          box-shadow: none;
          padding: 5px 9px;
        }

        .compact-form .form-control.input-invalid {
          border-color: #dc2626 !important;
          background: #fffafa;
          box-shadow:
            0 0 0 2px rgba(220,38,38,0.06);
        }

        .field-error {
          font-size: 11px;
          line-height: 1.25;
          color: #b91c1c;
          margin-top: 2px;
        }

        .predict-button {
          width: 100%;
          margin-top: 7px;
          padding: 9px 14px;
          border-radius: 6px;
          font-weight: 600;
        }

        .prediction-card {
          min-height: 395px;
          display: flex;
          flex-direction: column;
          justify-content: center;
          text-align: center;
        }

        .prediction-placeholder {
          color: #9ca3af;
        }

        .placeholder-icon {
          font-size: 34px;
          color: #cbd5e1;
          margin-bottom: 10px;
        }

        .prediction-label {
          font-size: 21px;
          font-weight: 700;
          text-transform: uppercase;
          margin-bottom: 12px;
        }

        .learner-label {
          font-size: 18px;
          color: #4b5563;
          margin-bottom: 18px;
        }


        .risk-number {
          font-size: 62px;
          line-height: 1;
          font-weight: 700;
          margin-bottom: 8px;
        }

        .risk-caption {
          font-size: 16px;
          color: #4b5563;
        }


        .assessment-error-state {
          max-width: 380px;
          margin: 0 auto;
          text-align: center;
        }

        .assessment-error-icon {
          width: 42px;
          height: 42px;
          line-height: 38px;
          border-radius: 50%;
          margin: 0 auto 12px auto;
          border: 2px solid #fecaca;
          background: #fef2f2;
          color: #b91c1c;
          font-size: 23px;
          font-weight: 700;
        }

        .assessment-error-title {
          font-size: 19px;
          font-weight: 650;
          color: #991b1b;
          margin-bottom: 7px;
        }

        .assessment-error-text {
          font-size: 14px;
          line-height: 1.45;
          color: #6b7280;
        }

        .assessment-api-detail {
          margin-top: 10px;
          font-size: 12px;
          color: #9ca3af;
        }

        /* ====================================================
           Batch input
           ==================================================== */

        .batch-card {
          padding: 14px 18px 10px 18px;
          margin-bottom: 0;
        }

        .batch-card .form-group {
          margin-bottom: 0;
        }

        .batch-card label {
          font-size: 12px;
          font-weight: 600;
          color: #4b5563;
          margin-bottom: 2px;
        }

        .batch-card .form-control {
          height: 32px;
          border-radius: 6px;
          border-color: #d1d5db;
          box-shadow: none;
        }

        .batch-card .progress {
          display: none;
        }

        .batch-file-invalid .form-control,
        .batch-file-invalid .btn-file {
          border-color: #dc2626 !important;
        }

        .batch-field-error {
          font-size: 11px;
          line-height: 1.3;
          color: #b91c1c;
          margin-top: 3px;
        }

        .batch-file-status {
          color: #15803d;
          font-size: 11.5px;
          margin-top: 3px;
        }

        .batch-input-actions {
          padding-top: 20px;
        }

        .batch-input-actions .btn {
          width: 100%;
          height: 32px;
          border-radius: 6px;
          font-size: 12px;
          font-weight: 600;
        }

        .batch-preview {
          border-top: 1px solid #e5e7eb;
          margin-top: 10px;
          padding-top: 7px;
        }

        .batch-preview-title {
          font-size: 13px;
          font-weight: 650;
          margin-bottom: 3px;
        }

        .batch-empty {
          border-top: 1px solid #e5e7eb;
          margin-top: 10px;
          padding: 12px 0 6px 0;
          text-align: center;
          color: #9ca3af;
          font-size: 12px;
        }

        .batch-service-error {
          border-top: 1px solid #e5e7eb;
          margin-top: 10px;
          padding-top: 15px;
          padding-bottom: 8px;
        }

        /* ====================================================
           Batch result
           ==================================================== */

        .batch-result-card {
          padding: 9px 18px 7px 18px;
          margin-bottom: 0;
        }

        .batch-result-meta {
          display: flex;
          justify-content: space-between;
          align-items: center;
          gap: 12px;
          padding-bottom: 6px;
          border-bottom: 1px solid #e5e7eb;
        }

        .batch-meta-text {
          font-size: 12px;
          color: #6b7280;
        }

        .batch-meta-file {
          font-weight: 650;
          color: #374151;
        }

        .new-batch-button {
          padding: 4px 9px;
          font-size: 11.5px;
        }

        .batch-toolbar {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 10px;
          padding: 6px 0 3px 0;
        }

        .batch-summary {
          font-size: 12.5px;
          color: #4b5563;
          white-space: nowrap;
        }

        .batch-summary-number {
          font-size: 17px;
          font-weight: 700;
          color: #111827;
        }

        .batch-summary-rejected {
          color: #b91c1c;
        }

        .batch-summary-separator {
          color: #d1d5db;
          padding: 0 6px;
        }

        .batch-downloads {
          display: flex;
          gap: 5px;
          white-space: nowrap;
        }

        .batch-downloads .btn {
          padding: 4px 8px;
          font-size: 11px;
        }

        .batch-tabs .nav-tabs {
          margin-bottom: 3px;
        }

        .batch-tabs .nav-tabs > li > a {
          padding: 5px 10px;
          font-size: 12px;
        }

        /* ====================================================
           Tables
           ==================================================== */

        .batch-table .table {
          width: auto;
          margin-bottom: 0;
        }

        .batch-table .table > thead > tr > th {
          padding: 3px 8px;
          font-size: 11.5px;
          white-space: nowrap;
        }

        .batch-table .table > tbody > tr > td {
          padding: 2px 8px;
          font-size: 11.5px;
        }

        .queue-scroll {
          width: 100%;
          height: 300px;
          max-height: 300px;
          overflow-y: scroll;
          overflow-x: auto;
          scrollbar-gutter: stable;
          border: 1px solid #e5e7eb;
          border-radius: 4px;
          background: #ffffff;
        }

        .queue-scroll .queue-table {
          margin-bottom: 0;
        }

        .queue-scroll .table {
          margin-bottom: 0;
        }

        .queue-scroll .table > thead > tr > th,
        .queue-scroll .table > tbody > tr > td {
          padding-top: 4px;
          padding-bottom: 4px;
        }

        .queue-scroll .table > thead > tr > th {
          position: sticky;
          top: 0;
          z-index: 2;
          background: #ffffff;
          box-shadow: 0 1px 0 #d1d5db;
        }

        .queue-table .table {
          min-width: 430px;
        }

        .prediction-table .table {
          min-width: 620px;
        }

        /* Keep the main risk signal visually prominent at the far right. */
        .queue-table .table > thead > tr > th:last-child,
        .queue-table .table > tbody > tr > td:last-child,
        .prediction-table .table > thead > tr > th:last-child,
        .prediction-table .table > tbody > tr > td:last-child {
          font-weight: 700;
        }

        .queue-table .table > thead > tr > th:last-child,
        .prediction-table .table > thead > tr > th:last-child {
          border-left: 2px solid #d1d5db;
        }

        .rejected-scroll {
          width: 100%;
          height: 300px;
          max-height: 300px;
          overflow-y: scroll;
          overflow-x: auto;
          scrollbar-gutter: stable;
          border: 1px solid #e5e7eb;
          border-radius: 4px;
          background: #ffffff;
        }

        .rejected-scroll .rejected-table,
        .rejected-scroll .table {
          margin-bottom: 0;
        }

        .rejected-scroll .table > thead > tr > th {
          position: sticky;
          top: 0;
          z-index: 2;
          background: #ffffff;
          box-shadow: 0 1px 0 #d1d5db;
        }

        .rejected-scroll .table > thead > tr > th,
        .rejected-scroll .table > tbody > tr > td {
          padding-top: 4px;
          padding-bottom: 4px;
        }

        .rejected-table .table {
          width: 100%;
        }

        .preview-table {
          width: 100%;
          max-width: 100%;
          overflow: visible;
        }

        .preview-table .table {
          width: 100%;
          min-width: 0;
          table-layout: fixed;
        }

        .preview-table .table > thead > tr > th {
          padding: 3px 4px;
          font-size: 10.5px;
          line-height: 1.15;
          white-space: normal;
          overflow-wrap: anywhere;
          vertical-align: bottom;
        }

        .preview-table .table > tbody > tr > td {
          padding: 2px 4px;
          font-size: 10.5px;
          line-height: 1.15;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .preview-table .table th:nth-child(1),
        .preview-table .table td:nth-child(1) {
          width: 8%;
        }

        .preview-table .table th:nth-child(2),
        .preview-table .table td:nth-child(2),
        .preview-table .table th:nth-child(3),
        .preview-table .table td:nth-child(3) {
          width: 8%;
        }

        .preview-table .table th:nth-child(4),
        .preview-table .table td:nth-child(4) {
          width: 7%;
        }

        .preview-table .table th:nth-child(5),
        .preview-table .table td:nth-child(5) {
          width: 8%;
        }

        .preview-table .table th:nth-child(6),
        .preview-table .table td:nth-child(6),
        .preview-table .table th:nth-child(7),
        .preview-table .table td:nth-child(7) {
          width: 11%;
        }

        .preview-table .table th:nth-child(8),
        .preview-table .table td:nth-child(8),
        .preview-table .table th:nth-child(9),
        .preview-table .table td:nth-child(9) {
          width: 8%;
        }

        .preview-table .table th:nth-child(10),
        .preview-table .table td:nth-child(10),
        .preview-table .table th:nth-child(11),
        .preview-table .table td:nth-child(11) {
          width: 11%;
        }

        .empty-table-message {
          color: #6b7280;
          font-size: 12px;
          padding: 15px 3px;
        }

        @media (max-width: 1100px) {

          .single-page-row {
            display: block;
          }

          .single-page-row > div {
            display: block;
          }

          .prediction-card,
          .single-input-card {
            min-height: auto;
          }

          .batch-result-meta,
          .batch-toolbar {
            display: block;
          }

          .batch-downloads {
            margin-top: 5px;
          }

          .batch-input-actions {
            padding-top: 0;
          }
        }
        "
      )
    )
  ),


  tags$div(
    class = "app-container",


    # ==========================================================
    # Header
    # ==========================================================

    tags$div(
      class = "app-title",
      "Learner Non-Completion Risk"
    ),


    tags$div(
      class = "app-subtitle",
      "Early identification of learners who may need retention support."
    ),


    tags$div(
      class = "top-info-row",

      tags$div(
        class = "observation-box",

        tags$strong(
          "Observation window: "
        ),

        "First 10 course days. All activity features must represent this period."
      ),


      tags$div(
        class = "api-panel",

        tags$div(
          class = "api-status-wrapper",

          uiOutput(
            "api_status",
            inline = TRUE
          )
        ),


        actionButton(
          "check_api",
          "Reconnect",
          class = "btn-default btn-sm reconnect-button"
        )
      )
    ),


    # ==========================================================
    # Main tabs
    # ==========================================================

    tabsetPanel(
      id = "prediction_mode",


      # ========================================================
      # SINGLE LEARNER
      # ========================================================

      tabPanel(
        "Single Learner",
        value = "single",


        fluidRow(
          class = "single-page-row",


          column(
            width = 8,


            tags$div(
              class = "section-card single-input-card compact-form",


              fluidRow(

                column(
                  width = 3,

                  numericInput(
                    "user_id",
                    "User ID",
                    value = 1002,
                    step = 1,
                    width = "100%"
                  ),

                  uiOutput(
                    "user_id_error"
                  )
                )
              ),


              # OVERALL COURSE ACTIVITY
              tags$div(
                class = "feature-section",

                tags$div(
                  class = "feature-section-heading",
                  "Overall course activity"
                ),


                fluidRow(

                  learner_input_column(
                    3,
                    "n_viewed_all",
                    "Viewed steps",
                    15,
                    1
                  ),

                  learner_input_column(
                    3,
                    "n_passed_all",
                    "Passed steps",
                    3,
                    1
                  ),

                  learner_input_column(
                    3,
                    "active_days",
                    "Active days",
                    3,
                    1
                  ),

                  learner_input_column(
                    3,
                    "days_since_last_action",
                    "Days since last action",
                    6,
                    1
                  )
                )
              ),


              # PRACTICAL ENGAGEMENT ONLY
              tags$div(
                class = "feature-section",

                tags$div(
                  class = "feature-section-heading",
                  "Practical engagement only"
                ),


                fluidRow(

                  learner_input_column(
                    3,
                    "n_started_practical",
                    "Started practical steps",
                    2,
                    1
                  ),

                  learner_input_column(
                    3,
                    "n_passed_practical",
                    "Passed practical steps",
                    1,
                    1
                  ),

                  learner_input_column(
                    3,
                    "n_submissions",
                    "Submissions",
                    4,
                    1
                  ),

                  learner_input_column(
                    3,
                    "submission_correct_rate",
                    "Correct submission rate",
                    0.25,
                    0.01
                  )
                )
              ),


              # ACTIVITY INTENSITY
              tags$div(
                class = "feature-section",

                tags$div(
                  class = "feature-section-heading",
                  "Activity intensity"
                ),


                fluidRow(

                  learner_input_column(
                    6,
                    "steps_per_active_day",
                    "Steps per active day",
                    5,
                    0.01
                  ),

                  learner_input_column(
                    6,
                    "score_per_active_day",
                    "Score per active day",
                    1,
                    0.01
                  )
                )
              ),


              actionButton(
                "predict",
                "Assess learner",
                class = "btn-primary predict-button"
              )
            )
          ),


          column(
            width = 4,


            tags$div(
              class = "section-card prediction-card",

              uiOutput(
                "prediction_summary"
              )
            )
          )
        )
      ),


      # ========================================================
      # BATCH XLSX
      # ========================================================

      tabPanel(
        "Batch XLSX",
        value = "batch",


        conditionalPanel(
          condition =
            "output.batch_result_ready != 'true'",


          fluidRow(

            column(
              width = 12,


              tags$div(
                class = "section-card batch-card",


                fluidRow(

                  column(
                    width = 5,


                    tags$div(
                      id = "batch_file_wrapper",


                      uiOutput(
                        "batch_file_input"
                      )
                    ),


                    uiOutput(
                      "batch_file_error"
                    ),


                    uiOutput(
                      "batch_file_status"
                    )
                  ),


                  column(
                    width = 3,


                    uiOutput(
                      "batch_top_n_input"
                    ),


                    uiOutput(
                      "batch_capacity_error"
                    )
                  ),


                  column(
                    width = 3,


                    tags$div(
                      class = "batch-input-actions",

                      actionButton(
                        "score_batch",
                        "Assess learners",
                        class = "btn-primary"
                      )
                    )
                  )
                ),


                uiOutput(
                  "batch_input_content"
                )
              )
            )
          )
        ),


        conditionalPanel(
          condition =
            "output.batch_result_ready == 'true'",

          uiOutput(
            "batch_result_page"
          )
        )
      )
    )
  )
)


# ============================================================
# Server
# ============================================================

server <- function(
  input,
  output,
  session
) {


  # ==========================================================
  # API health
  # ==========================================================

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

      return(
        tagList(

          tags$span(
            class = "api-dot api-connected"
          ),

          tags$span(
            class = "api-text-success",
            "API connected"
          )
        )
      )
    }


    tagList(

      tags$span(
        class = "api-dot api-disconnected"
      ),

      tags$span(
        class = "api-text-error",
        "API unavailable"
      )
    )
  })


  # ==========================================================
  # Single learner
  # ==========================================================

  current_single_values <- reactive({

    list(
      user_id =
        as.numeric(input$user_id),

      n_viewed_all =
        as.numeric(input$n_viewed_all),

      n_passed_all =
        as.numeric(input$n_passed_all),

      active_days =
        as.numeric(input$active_days),

      days_since_last_action =
        as.numeric(input$days_since_last_action),

      n_started_practical =
        as.numeric(input$n_started_practical),

      n_passed_practical =
        as.numeric(input$n_passed_practical),

      n_submissions =
        as.numeric(input$n_submissions),

      submission_correct_rate =
        as.numeric(input$submission_correct_rate),

      steps_per_active_day =
        as.numeric(input$steps_per_active_day),

      score_per_active_day =
        as.numeric(input$score_per_active_day)
    )
  })


  assessment_attempted <- reactiveVal(
    FALSE
  )


  current_validation_errors <- reactive({

    if (!isTRUE(assessment_attempted())) {

      return(list())
    }


    validate_single_learner(
      current_single_values()
    )
  })


  validation_fields <- c(
    "user_id",
    "n_viewed_all",
    "n_passed_all",
    "active_days",
    "days_since_last_action",
    "n_started_practical",
    "n_passed_practical",
    "n_submissions",
    "submission_correct_rate",
    "steps_per_active_day",
    "score_per_active_day"
  )


  for (field_name in validation_fields) {

    local({

      current_field <- field_name


      output[[
        paste0(
          current_field,
          "_error"
        )
      ]] <- renderUI({

        errors <-
          current_validation_errors()


        message <-
          errors[[current_field]]


        if (is.null(message)) {

          return(NULL)
        }


        tags$div(
          class = "field-error",

          paste0(
            "⚠ ",
            message
          )
        )
      })
    })
  }


  observe({

    errors <-
      current_validation_errors()


    for (field_name in validation_fields) {

      session$sendCustomMessage(
        "setInputError",

        list(
          id = field_name,

          hasError =
            field_name %in%
              names(errors)
        )
      )
    }
  })


  assessment_result <- eventReactive(
    input$predict,
    {

      assessment_attempted(TRUE)


      values <-
        current_single_values()


      errors <-
        validate_single_learner(values)


      if (length(errors) > 0L) {

        return(
          list(
            type = "validation_error",
            api_result = NULL
          )
        )
      }


      api_result <-
        request_prediction(values)


      if (!isTRUE(api_result$success)) {

        return(
          list(
            type = "api_error",
            api_result = api_result
          )
        )
      }


      list(
        type = "success",
        api_result = api_result
      )
    }
  )

  output$prediction_summary <- renderUI({

    if (input$predict == 0L) {

      return(
        tags$div(
          class = "prediction-placeholder",

          tags$div(
            class = "placeholder-icon",
            "◎"
          ),

          tags$h4(
            "No assessment yet"
          ),

          tags$p(
            "Enter learner activity and select \"Assess learner\"."
          )
        )
      )
    }


    result <-
      assessment_result()


    if (
      identical(
        result$type,
        "validation_error"
      )
    ) {

      return(
        tagList(

          tags$div(
            class = "prediction-label",
            "Non-completion assessment"
          ),

          tags$div(
            class = "assessment-error-state",

            tags$div(
              class = "assessment-error-icon",
              "!"
            ),

            tags$div(
              class = "assessment-error-title",
              "Unable to assess learner"
            ),

            tags$div(
              class = "assessment-error-text",
              "Please correct the highlighted fields and run the assessment again."
            )
          )
        )
      )
    }


    if (
      identical(
        result$type,
        "api_error"
      )
    ) {

      return(
        tagList(

          tags$div(
            class = "prediction-label",
            "Non-completion assessment"
          ),

          tags$div(
            class = "assessment-error-state",

            tags$div(
              class = "assessment-error-icon",
              "!"
            ),

            tags$div(
              class = "assessment-error-title",
              "Assessment unavailable"
            ),

            tags$div(
              class = "assessment-error-text",
              "The assessment service could not process this request."
            ),

            tags$div(
              class = "assessment-api-detail",

              extract_error_message(
                result$api_result
              )
            )
          )
        )
      )
    }


    api_result <-
      result$api_result


    completion_risk <- as.numeric(
      api_result$body$completion_risk
    )



    tagList(

      tags$div(
        class = "prediction-label",
        "Non-completion assessment"
      ),

      tags$div(
        class = "learner-label",

        paste(
          "Learner",
          api_result$body$user_id
        )
      ),

      tags$div(
        class = "risk-number",

        sprintf(
          "%.1f%%",
          completion_risk * 100
        )
      ),

      tags$div(
        class = "risk-caption",
        "Estimated non-completion probability"
      )
    )
  })

  # ==========================================================
  # Batch state
  # ==========================================================

  batch_result <- reactiveVal(NULL)

  # Keep uploaded XLSX data in explicit application state.
  # We intentionally do not use input$batch_file as the source
  # of truth after upload because a dynamically rebuilt fileInput
  # can leave the previous server-side input value available.
  batch_uploaded_data <-
    reactiveVal(NULL)

  batch_uploaded_name <-
    reactiveVal(NULL)

  batch_file_error_message <-
    reactiveVal(NULL)

  batch_capacity_error_message <-
    reactiveVal(NULL)

  batch_service_error_message <-
    reactiveVal(NULL)

  # Incrementing this value rebuilds both batch inputs.
  batch_input_version <-
    reactiveVal(0L)


  reset_batch_state <- function() {

    # Clear all batch data and results.
    batch_result(NULL)

    batch_uploaded_data(NULL)

    batch_uploaded_name(NULL)


    # Clear all local messages.
    batch_file_error_message(NULL)

    batch_capacity_error_message(NULL)

    batch_service_error_message(NULL)


    # Remove possible file-input error styling.
    session$sendCustomMessage(
      "setBatchFileError",

      list(
        hasError = FALSE
      )
    )


    # Rebuild file input and capacity input.
    # The new file input is visually empty and Top N returns to 10.
    batch_input_version(
      batch_input_version() + 1L
    )
  }


  # ==========================================================
  # Dynamic batch inputs
  # ==========================================================

  output$batch_file_input <- renderUI({

    batch_input_version()


    fileInput(
      "batch_file",
      "Learner XLSX",
      accept = c(
        ".xlsx",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      ),
      width = "100%"
    )
  })


  output$batch_top_n_input <- renderUI({

    batch_input_version()


    numericInput(
      "batch_top_n",
      "Learners to prioritize",
      value = 10,
      min = 1,
      step = 1,
      width = "100%"
    )
  })


  # ==========================================================
  # Reset Batch XLSX whenever the user returns to the tab
  # ==========================================================

  observeEvent(
    input$prediction_mode,
    {

      if (
        identical(
          input$prediction_mode,
          "batch"
        )
      ) {

        reset_batch_state()
      }
    },
    ignoreInit = TRUE
  )


  # ==========================================================
  # Batch file
  # ==========================================================

  observeEvent(
    input$batch_file,
    {

      if (is.null(input$batch_file)) {

        return()
      }


      # Selecting another file always starts a new assessment.
      batch_result(NULL)

      batch_uploaded_data(NULL)

      batch_uploaded_name(NULL)

      batch_file_error_message(NULL)

      batch_capacity_error_message(NULL)

      batch_service_error_message(NULL)


      session$sendCustomMessage(
        "setBatchFileError",

        list(
          hasError = FALSE
        )
      )


      uploaded_file <-
        input$batch_file


      tryCatch(
        {
          data <- readxl::read_excel(
            uploaded_file$datapath
          )

          data <- as.data.frame(
            data,
            check.names = FALSE,
            stringsAsFactors = FALSE
          )


          batch_uploaded_data(data)

          batch_uploaded_name(
            uploaded_file$name
          )
        },
        error = function(error) {

          batch_uploaded_data(NULL)

          batch_uploaded_name(NULL)


          batch_file_error_message(
            "The selected file could not be read as an XLSX file."
          )


          session$sendCustomMessage(
            "setBatchFileError",

            list(
              hasError = TRUE
            )
          )
        }
      )
    },
    ignoreInit = TRUE
  )


  batch_file_result <- reactive({

    data <-
      batch_uploaded_data()


    if (is.null(data)) {

      return(
        list(
          success = FALSE,
          data = NULL,
          error = NULL
        )
      )
    }


    list(
      success = TRUE,
      data = data,
      error = NULL
    )
  })


  # ==========================================================
  # Keep prioritization capacity within uploaded row count
  # ==========================================================

  observe({

    file_result <-
      batch_file_result()


    if (
      isTRUE(file_result$success) &&
      is.data.frame(file_result$data) &&
      nrow(file_result$data) > 0L
    ) {

      uploaded_count <-
        nrow(file_result$data)


      current_capacity <- suppressWarnings(
        as.numeric(
          input$batch_top_n
        )
      )


      if (
        length(current_capacity) != 1L ||
        is.na(current_capacity) ||
        !is.finite(current_capacity)
      ) {

        current_capacity <- 10
      }


      updateNumericInput(
        session,
        "batch_top_n",
        min = 1,
        max = uploaded_count,
        value = min(
          max(
            1,
            round(current_capacity)
          ),
          uploaded_count
        )
      )
    }
  })


  # ==========================================================
  # Keep input and result UI states separate
  # ==========================================================

  output$batch_result_ready <- renderText({

    result <- batch_result()


    if (
      !is.null(result) &&
      isTRUE(result$success)
    ) {

      "true"

    } else {

      "false"
    }
  })


  outputOptions(
    output,
    "batch_result_ready",
    suspendWhenHidden = FALSE
  )


  # ==========================================================
  # Batch local error outputs
  # ==========================================================

  output$batch_file_error <- renderUI({

    message <-
      batch_file_error_message()


    if (is.null(message)) {

      return(NULL)
    }


    tags$div(
      class = "batch-field-error",

      paste0(
        "⚠ ",
        message
      )
    )
  })


  output$batch_capacity_error <- renderUI({

    message <-
      batch_capacity_error_message()


    if (is.null(message)) {

      return(NULL)
    }


    tags$div(
      class = "batch-field-error",

      paste0(
        "⚠ ",
        message
      )
    )
  })


  # ==========================================================
  # Loaded-file status
  # ==========================================================

  output$batch_file_status <- renderUI({

    result <-
      batch_file_result()


    if (!isTRUE(result$success)) {

      return(NULL)
    }


    tags$div(
      class = "batch-file-status",

      paste0(
        nrow(result$data),
        " learners loaded · ",
        ncol(result$data),
        " columns"
      )
    )
  })


  # ==========================================================
  # Batch input content:
  # preview / empty / API error
  # ==========================================================

  output$batch_input_content <- renderUI({

    service_error <-
      batch_service_error_message()


    if (!is.null(service_error)) {

      return(
        tags$div(
          class = "batch-service-error",

          tags$div(
            class = "assessment-error-state",

            tags$div(
              class = "assessment-error-icon",
              "!"
            ),

            tags$div(
              class = "assessment-error-title",
              "Batch assessment unavailable"
            ),

            tags$div(
              class = "assessment-error-text",
              "The assessment service could not process this batch."
            ),

            tags$div(
              class = "assessment-api-detail",
              service_error
            )
          )
        )
      )
    }


    file_result <-
      batch_file_result()


    if (isTRUE(file_result$success)) {

      preview <-
        format_batch_input_preview(
          file_result$data
        )


      return(
        tags$div(
          class = "batch-preview",


          tags$div(
            class = "batch-preview-title",

            paste0(
              "XLSX preview · first ",
              nrow(preview),
              " of ",
              nrow(file_result$data),
              " learners"
            )
          ),


          compact_table_ui(
            preview,
            "preview-table"
          )
        )
      )
    }


    tags$div(
      class = "batch-empty",

      "Upload a learner XLSX to assess multiple learners."
    )
  })


  # ==========================================================
  # New batch
  # ==========================================================

  observeEvent(
    input$new_batch,
    {

      reset_batch_state()
    },
    ignoreInit = TRUE
  )


  # ==========================================================
  # Batch assessment
  # ==========================================================

  observeEvent(
    input$score_batch,
    {

      # Reset local errors.
      batch_file_error_message(NULL)

      batch_capacity_error_message(NULL)

      batch_service_error_message(NULL)


      session$sendCustomMessage(
        "setBatchFileError",

        list(
          hasError = FALSE
        )
      )


      # --------------------------------------------------------
      # File selected?
      # --------------------------------------------------------

      file_result <-
        batch_file_result()


      if (!isTRUE(file_result$success)) {

        batch_file_error_message(
          "Please upload a learner XLSX file."
        )


        session$sendCustomMessage(
          "setBatchFileError",

          list(
            hasError = TRUE
          )
        )


        return()
      }


      # --------------------------------------------------------
      # Learners to prioritize
      # --------------------------------------------------------

      capacity <- suppressWarnings(
        as.numeric(
          input$batch_top_n
        )
      )


      capacity_valid <- (
        length(capacity) == 1L &&
          !is.na(capacity) &&
          is.finite(capacity) &&
          capacity > 0 &&
          capacity == round(capacity)
      )


      if (!capacity_valid) {

        batch_capacity_error_message(
          "Enter a positive whole number."
        )


        return()
      }


      uploaded_count <-
        nrow(
          file_result$data
        )


      if (capacity > uploaded_count) {

        batch_capacity_error_message(
          paste0(
            "Cannot prioritize more than ",
            uploaded_count,
            " learners in the uploaded file."
          )
        )


        return()
      }


      # --------------------------------------------------------
      # Validate uploaded learners
      # --------------------------------------------------------

      validation_result <-
        validate_batch_rows(
          file_result$data
        )


      if (!isTRUE(validation_result$success)) {

        batch_file_error_message(
          validation_result$error
        )


        session$sendCustomMessage(
          "setBatchFileError",

          list(
            hasError = TRUE
          )
        )


        return()
      }


      valid_data <-
        validation_result$valid_data


      validation_errors <-
        validation_result$validation_errors


      # --------------------------------------------------------
      # Capacity after row validation
      # --------------------------------------------------------

      valid_count <-
        nrow(
          valid_data
        )


      if (
        valid_count > 0L &&
        capacity > valid_count
      ) {

        batch_capacity_error_message(
          paste0(
            "Only ",
            valid_count,
            " valid learners can be prioritized after validation."
          )
        )


        return()
      }


      file_name <-
        batch_uploaded_name()


      if (
        is.null(file_name) ||
        length(file_name) != 1L ||
        is.na(file_name) ||
        !nzchar(file_name)
      ) {

        file_name <- "uploaded_batch.xlsx"
      }


      # --------------------------------------------------------
      # All rows rejected
      # --------------------------------------------------------

      if (nrow(valid_data) == 0L) {

        batch_result(
          list(
            success = TRUE,

            file_name = file_name,

            uploaded_count =
              validation_result$uploaded_count,

            scored_count = 0L,

            rejected_count =
              validation_result$rejected_count,

            capacity = capacity,

            predictions = data.frame(),

            queue = data.frame(),

            validation_errors =
              validation_errors
          )
        )


        return()
      }


      # --------------------------------------------------------
      # Send valid learners to backend
      # --------------------------------------------------------

      payload <- list(

        learners =
          data_frame_to_records(
            valid_data
          ),

        top_n = capacity
      )


      api_result <-
        request_batch_prediction(
          payload
        )


      if (!isTRUE(api_result$success)) {

        batch_service_error_message(
          extract_error_message(
            api_result
          )
        )


        return()
      }


      predictions <-
        records_to_data_frame(
          api_result$body$predictions
        )


      queue <-
        records_to_data_frame(
          api_result$body$retention_queue
        )


      # Make both probabilities available to the UI even if an
      # older API response contains only one of them.
      predictions <-
        ensure_probability_columns(
          predictions
        )

      queue <-
        ensure_probability_columns(
          queue
        )


      batch_result(
        list(
          success = TRUE,

          file_name = file_name,

          uploaded_count =
            validation_result$uploaded_count,

          scored_count =
            nrow(predictions),

          rejected_count =
            validation_result$rejected_count,

          capacity = capacity,

          predictions = predictions,

          queue = queue,

          validation_errors =
            validation_errors
        )
      )
    }
  )


  # ==========================================================
  # Batch metrics
  # ==========================================================

  batch_metrics <- reactive({

    result <-
      batch_result()


    req(
      !is.null(result),
      isTRUE(result$success)
    )


    list(
      scored =
        result$scored_count,

      rejected =
        result$rejected_count,

      queue =
        if (
          is.data.frame(result$queue)
        ) {
          nrow(result$queue)
        } else {
          0L
        }
    )
  })

  # ==========================================================
  # Batch result page
  # ==========================================================

  output$batch_result_page <- renderUI({

    result <-
      batch_result()


    req(
      !is.null(result),
      isTRUE(result$success)
    )


    metrics <-
      batch_metrics()




    # ----------------------------------------------------------
    # Queue
    # ----------------------------------------------------------

    queue_tab <- tabPanel(
      "Priority intervention queue",

      queue_table_ui(
        result$queue
      )
    )


    # ----------------------------------------------------------
    # All scored learners
    # ----------------------------------------------------------

    predictions_tab <- tabPanel(
      "All scored learners",

      tags$div(
        class = "queue-scroll",

        compact_table_ui(
          format_predictions_for_display(
            result$predictions
          ),
          "prediction-table"
        )
      )
    )


    # ----------------------------------------------------------
    # Rejected rows
    # ----------------------------------------------------------

    result_tabs <- list(
      queue_tab,
      predictions_tab
    )


    if (result$rejected_count > 0L) {

      rejected_preview <-
        result$validation_errors


      result_tabs <- append(
        result_tabs,

        list(
          tabPanel(
            paste0(
              "Rejected rows (",
              result$rejected_count,
              ")"
            ),

            tags$div(
              class = "rejected-scroll",

              compact_table_ui(
                rejected_preview,
                "rejected-table"
              )
            )
          )
        )
      )
    }


    inner_tabs <- do.call(
      tabsetPanel,

      c(
        list(
          id = "batch_result_tab"
        ),
        result_tabs
      )
    )


    # ----------------------------------------------------------
    # Download buttons
    # ----------------------------------------------------------

    download_buttons <- list(

      downloadButton(
        "download_queue",
        "Download queue",
        class = "btn-default"
      ),

      downloadButton(
        "download_predictions",
        "Download full results",
        class = "btn-default"
      )
    )


    if (result$rejected_count > 0L) {

      download_buttons <- append(
        download_buttons,

        list(
          downloadButton(
            "download_validation_errors",
            "Download validation errors",
            class = "btn-default"
          )
        )
      )
    }


    # ----------------------------------------------------------
    # Result UI
    # ----------------------------------------------------------

    fluidRow(

      column(
        width = 12,


        tags$div(
          class =
            "section-card batch-result-card",


          tags$div(
            class = "batch-result-meta",


            tags$div(
              class = "batch-meta-text",


              tags$span(
                class = "batch-meta-file",
                result$file_name
              ),


              paste0(
                " · ",
                result$uploaded_count,
                " learners",
                " · Prioritize ",
                result$capacity
              )
            ),


            actionButton(
              "new_batch",
              "New batch",
              class =
                "btn-default new-batch-button"
            )
          ),


          tags$div(
            class = "batch-toolbar",


            tags$div(
              class = "batch-summary",


              tags$span(
                class = "batch-summary-number",
                metrics$scored
              ),

              " scored",


              tags$span(
                class =
                  "batch-summary-separator",
                "·"
              ),


              tags$span(
                class = paste(
                  "batch-summary-number",
                  if (
                    metrics$rejected > 0L
                  ) {
                    "batch-summary-rejected"
                  } else {
                    ""
                  }
                ),

                metrics$rejected
              ),

              " rejected",


              tags$span(
                class =
                  "batch-summary-separator",
                "·"
              ),


              tags$span(
                class = "batch-summary-number",
                metrics$queue
              ),

              " prioritized"
            ),


            do.call(
              tags$div,

              c(
                list(
                  class = "batch-downloads"
                ),
                download_buttons
              )
            )
          ),


          tags$div(
            class = "batch-tabs",

            inner_tabs
          )
        )
      )
    )
  })


  # ==========================================================
  # Downloads
  # ==========================================================

  output$download_predictions <- downloadHandler(

    filename = function() {

      paste0(
        "non_completion_scoring_results_",
        Sys.Date(),
        ".xlsx"
      )
    },

    contentType =
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",

    content = function(file) {

      result <-
        batch_result()


      req(
        !is.null(result),
        isTRUE(result$success)
      )


      predictions_for_download <-
        order_probability_columns(
          result$predictions
        )


      writexl::write_xlsx(
        list(
          `Scored learners` =
            predictions_for_download
        ),
        path = file
      )
    }
  )


  output$download_queue <- downloadHandler(

    filename = function() {

      paste0(
        "priority_intervention_queue_",
        Sys.Date(),
        ".xlsx"
      )
    },

    contentType =
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",

    content = function(file) {

      result <-
        batch_result()


      req(
        !is.null(result),
        isTRUE(result$success)
      )


      queue_for_download <-
        order_probability_columns(
          result$queue
        )


      writexl::write_xlsx(
        list(
          `Priority queue` =
            queue_for_download
        ),
        path = file
      )
    }
  )


  output$download_validation_errors <- downloadHandler(

    filename = function() {

      paste0(
        "batch_validation_errors_",
        Sys.Date(),
        ".xlsx"
      )
    },

    contentType =
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",

    content = function(file) {

      result <-
        batch_result()


      req(
        !is.null(result),
        isTRUE(result$success),
        result$rejected_count > 0L
      )


      writexl::write_xlsx(
        list(
          `Validation errors` =
            result$validation_errors
        ),
        path = file
      )
    }
  )

}


# ============================================================
# Run
# ============================================================

shinyApp(
  ui = ui,
  server = server
)