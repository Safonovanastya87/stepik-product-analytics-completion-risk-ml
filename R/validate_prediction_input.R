# Validate and prepare input data for model prediction
validate_prediction_input <- function(
  data,
  feature_cols
) {
  # ============================================================
  # Validate general input structure
  # ============================================================

  if (!is.data.frame(data)) {
    stop(
      "`data` must be a data frame.",
      call. = FALSE
    )
  }

  if (nrow(data) == 0) {
    stop(
      "`data` must contain at least one row.",
      call. = FALSE
    )
  }

  if (
    !is.character(feature_cols) ||
    length(feature_cols) == 0
  ) {
    stop(
      "`feature_cols` must be a non-empty character vector.",
      call. = FALSE
    )
  }

  if (anyDuplicated(feature_cols) > 0) {
    stop(
      "`feature_cols` must not contain duplicate feature names.",
      call. = FALSE
    )
  }

  # ============================================================
  # Validate required feature columns
  # ============================================================

  missing_cols <- setdiff(
    feature_cols,
    names(data)
  )

  if (length(missing_cols) > 0) {
    stop(
      "Missing required features: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  # Keep only model features and preserve their required order
  feature_data <- data[
    ,
    feature_cols,
    drop = FALSE
  ]

  # ============================================================
  # Validate numeric types
  # ============================================================

  non_numeric_cols <- feature_cols[
    !vapply(
      feature_data,
      is.numeric,
      logical(1)
    )
  ]

  if (length(non_numeric_cols) > 0) {
    stop(
      "The following features must be numeric: ",
      paste(non_numeric_cols, collapse = ", "),
      call. = FALSE
    )
  }

  # ============================================================
  # Validate missing and non-finite values
  # ============================================================

  invalid_cols <- feature_cols[
    vapply(
      feature_data,
      function(column) {
        anyNA(column) ||
          any(!is.finite(column))
      },
      logical(1)
    )
  ]

  if (length(invalid_cols) > 0) {
    stop(
      "The following features contain invalid values: ",
      paste(invalid_cols, collapse = ", "),
      call. = FALSE
    )
  }

  # ============================================================
  # Internal validation helpers
  # ============================================================

  format_rows <- function(rows) {
    paste(rows, collapse = ", ")
  }

  validate_integer_feature <- function(feature_name) {
    values <- feature_data[[feature_name]]

    tolerance <- sqrt(.Machine$double.eps)

    invalid_rows <- which(
      abs(values - round(values)) > tolerance
    )

    if (length(invalid_rows) > 0) {
      stop(
        sprintf(
          "`%s` must contain whole numbers. Invalid row(s): %s.",
          feature_name,
          format_rows(invalid_rows)
        ),
        call. = FALSE
      )
    }
  }

  validate_feature_range <- function(
    feature_name,
    minimum = -Inf,
    maximum = Inf
  ) {
    values <- feature_data[[feature_name]]

    invalid_rows <- which(
      values < minimum |
        values > maximum
    )

    if (length(invalid_rows) == 0) {
      return(invisible(NULL))
    }

    if (
      is.finite(minimum) &&
      is.finite(maximum)
    ) {
      requirement <- sprintf(
        "between %s and %s",
        minimum,
        maximum
      )
    } else if (is.finite(minimum)) {
      requirement <- sprintf(
        "greater than or equal to %s",
        minimum
      )
    } else {
      requirement <- sprintf(
        "less than or equal to %s",
        maximum
      )
    }

    stop(
      sprintf(
        "`%s` must be %s. Invalid row(s): %s.",
        feature_name,
        requirement,
        format_rows(invalid_rows)
      ),
      call. = FALSE
    )
  }

  stop_for_rows <- function(
    message,
    invalid_rows
  ) {
    if (length(invalid_rows) > 0) {
      stop(
        sprintf(
          "%s Invalid row(s): %s.",
          message,
          format_rows(invalid_rows)
        ),
        call. = FALSE
      )
    }
  }

  # ============================================================
  # Validate integer-valued features
  # ============================================================

  integer_features <- intersect(
    c(
      "n_passed_all",
      "n_viewed_all",
      "n_started_practical",
      "n_passed_practical",
      "n_submissions",
      "active_days",
      "days_since_last_action"
    ),
    feature_cols
  )

  for (feature_name in integer_features) {
    validate_integer_feature(feature_name)
  }

  # ============================================================
  # Validate business ranges
  # ============================================================

  range_rules <- list(
    n_passed_all = c(0, 198),
    n_viewed_all = c(0, Inf),
    n_started_practical = c(0, Inf),
    n_passed_practical = c(0, 76),
    n_submissions = c(0, Inf),
    submission_correct_rate = c(0, 1),
    active_days = c(1, 10),
    days_since_last_action = c(0, 9),
    score_per_active_day = c(0, 88),
    steps_per_active_day = c(0, 198)
  )

  applicable_range_rules <- intersect(
    names(range_rules),
    feature_cols
  )

  for (feature_name in applicable_range_rules) {
    limits <- range_rules[[feature_name]]

    validate_feature_range(
      feature_name = feature_name,
      minimum = limits[[1]],
      maximum = limits[[2]]
    )
  }

  # ============================================================
  # Validate logical relationships between features
  # ============================================================

  required_relation_features <- c(
    "n_passed_all",
    "n_started_practical",
    "n_passed_practical",
    "n_submissions"
  )

  if (
    all(
      required_relation_features %in%
        names(feature_data)
    )
  ) {
    invalid_rows <- which(
      feature_data$n_passed_practical >
        feature_data$n_passed_all
    )

    stop_for_rows(
      paste0(
        "`n_passed_practical` must not exceed ",
        "`n_passed_all`."
      ),
      invalid_rows
    )

    invalid_rows <- which(
      feature_data$n_passed_practical >
        feature_data$n_started_practical
    )

    stop_for_rows(
      paste0(
        "`n_passed_practical` must not exceed ",
        "`n_started_practical`."
      ),
      invalid_rows
    )

    invalid_rows <- which(
      feature_data$n_passed_practical > 0 &
        feature_data$n_submissions == 0
    )

    stop_for_rows(
      paste0(
        "A learner with passed practical steps ",
        "must have at least one submission."
      ),
      invalid_rows
    )

    invalid_rows <- which(
      feature_data$n_submissions > 0 &
        feature_data$n_started_practical == 0
    )

    stop_for_rows(
      paste0(
        "A learner with submissions must have ",
        "at least one started practical step."
      ),
      invalid_rows
    )
  }

  # Return validated features in model-required order
  feature_data
}