# Build a ranked queue of learners with high non-completion risk
build_retention_queue <- function(
  predictions,
  id_col = "user_id",
  min_risk = 0.5,
  top_n = NULL
) {
  # ============================================================
  # Validate input structure
  # ============================================================

  if (!is.data.frame(predictions)) {
    stop(
      "`predictions` must be a data frame.",
      call. = FALSE
    )
  }

  if (nrow(predictions) == 0L) {
    stop(
      "`predictions` must contain at least one row.",
      call. = FALSE
    )
  }

  if (
    length(id_col) != 1L ||
    !is.character(id_col) ||
    is.na(id_col) ||
    !nzchar(id_col)
  ) {
    stop(
      "`id_col` must be one non-empty column name.",
      call. = FALSE
    )
  }

  required_cols <- c(
    id_col,
    "completion_probability",
    "completion_risk"
  )

  missing_cols <- setdiff(
    required_cols,
    names(predictions)
  )

  if (length(missing_cols) > 0L) {
    stop(
      "Missing required columns: ",
      paste(
        missing_cols,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  # ============================================================
  # Validate identifiers
  # ============================================================

  learner_ids <- predictions[[id_col]]

  if (
    length(learner_ids) != nrow(predictions) ||
    anyNA(learner_ids)
  ) {
    stop(
      sprintf(
        "`%s` must contain one non-missing value per row.",
        id_col
      ),
      call. = FALSE
    )
  }

  # ============================================================
  # Validate prediction columns
  # ============================================================

  probability_cols <- c(
    "completion_probability",
    "completion_risk"
  )

  non_numeric_cols <- probability_cols[
    !vapply(
      predictions[
        ,
        probability_cols,
        drop = FALSE
      ],
      is.numeric,
      logical(1)
    )
  ]

  if (length(non_numeric_cols) > 0L) {
    stop(
      "The following columns must be numeric: ",
      paste(
        non_numeric_cols,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  invalid_probability_cols <- probability_cols[
    vapply(
      predictions[
        ,
        probability_cols,
        drop = FALSE
      ],
      function(column) {
        anyNA(column) ||
          any(!is.finite(column)) ||
          any(column < 0) ||
          any(column > 1)
      },
      logical(1)
    )
  ]

  if (length(invalid_probability_cols) > 0L) {
    stop(
      "The following columns must contain values between 0 and 1: ",
      paste(
        invalid_probability_cols,
        collapse = ", "
      ),
      call. = FALSE
    )
  }

  # ============================================================
  # Validate queue configuration
  # ============================================================

  if (
    length(min_risk) != 1L ||
    !is.numeric(min_risk) ||
    is.na(min_risk) ||
    !is.finite(min_risk) ||
    min_risk < 0 ||
    min_risk > 1
  ) {
    stop(
      "`min_risk` must be one finite number between 0 and 1.",
      call. = FALSE
    )
  }

  if (!is.null(top_n)) {
    valid_top_n <- (
      length(top_n) == 1L &&
        is.numeric(top_n) &&
        !is.na(top_n) &&
        is.finite(top_n) &&
        top_n >= 1 &&
        abs(top_n - round(top_n)) <=
          sqrt(.Machine$double.eps)
    )

    if (!isTRUE(valid_top_n)) {
      stop(
        "`top_n` must be NULL or a positive whole number.",
        call. = FALSE
      )
    }

    top_n <- as.integer(
      round(top_n)
    )
  }

  # ============================================================
  # Build ranked retention queue
  # ============================================================

  queue <- predictions[
    predictions$completion_risk >= min_risk,
    ,
    drop = FALSE
  ]

  queue <- queue[
    order(
      -queue$completion_risk,
      queue$completion_probability
    ),
    ,
    drop = FALSE
  ]

  if (!is.null(top_n)) {
    queue <- head(
      queue,
      top_n
    )
  }

  queue$risk_rank <- seq_len(
    nrow(queue)
  )

  first_cols <- c(
    id_col,
    "risk_rank",
    "completion_risk",
    "completion_probability"
  )

  queue <- queue[
    ,
    c(
      first_cols,
      setdiff(
        names(queue),
        first_cols
      )
    ),
    drop = FALSE
  ]

  rownames(queue) <- NULL

  queue
}