# Build a capacity-based priority intervention queue

build_retention_queue <- function(
  predictions,
  id_col = "user_id",
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
      paste0(
        "Missing required columns: ",
        paste(
          missing_cols,
          collapse = ", "
        ),
        "."
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


  if (anyDuplicated(learner_ids) > 0L) {

    stop(
      sprintf(
        "`%s` must contain unique learner identifiers.",
        id_col
      ),
      call. = FALSE
    )
  }


  # ============================================================
  # Validate probability columns
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
      paste0(
        "The following columns must be numeric: ",
        paste(
          non_numeric_cols,
          collapse = ", "
        ),
        "."
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
      paste0(
        "The following columns must contain ",
        "values between 0 and 1: ",
        paste(
          invalid_probability_cols,
          collapse = ", "
        ),
        "."
      ),
      call. = FALSE
    )
  }


  # ============================================================
  # Validate probability relationship
  # ============================================================

  expected_completion_risk <-
    1 - predictions$completion_probability


  inconsistent_rows <- which(
    abs(
      predictions$completion_risk -
        expected_completion_risk
    ) > 1e-8
  )


  if (length(inconsistent_rows) > 0L) {

    stop(
      paste0(
        "`completion_risk` must equal ",
        "1 - `completion_probability`. ",
        "Invalid row(s): ",
        paste(
          inconsistent_rows,
          collapse = ", "
        ),
        "."
      ),
      call. = FALSE
    )
  }


  # ============================================================
  # Validate prioritization capacity
  # ============================================================

  if (is.null(top_n)) {

    top_n <- nrow(predictions)
  }


  valid_top_n <- (
    length(top_n) == 1L &&
      is.numeric(top_n) &&
      !is.na(top_n) &&
      is.finite(top_n) &&
      top_n >= 1 &&
      abs(
        top_n - round(top_n)
      ) <= sqrt(.Machine$double.eps)
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


  if (top_n > nrow(predictions)) {

    stop(
      paste0(
        "`top_n` cannot exceed the number of ",
        "scored learners (",
        nrow(predictions),
        ")."
      ),
      call. = FALSE
    )
  }


  # ============================================================
  # Rank learners by non-completion risk
  # ============================================================

  ranking_order <- order(
    -predictions$completion_risk,
    seq_len(nrow(predictions))
  )


  ranked_predictions <- predictions[
    ranking_order,
    ,
    drop = FALSE
  ]


  ranked_predictions <- head(
    ranked_predictions,
    top_n
  )


  # ============================================================
  # Build strict priority queue output
  # ============================================================

  queue <- data.frame(
    risk_rank =
      seq_len(
        nrow(ranked_predictions)
      ),

    learner_id =
      ranked_predictions[[id_col]],

    completion_probability =
      ranked_predictions$
        completion_probability,

    completion_risk =
      ranked_predictions$
        completion_risk,

    stringsAsFactors = FALSE,
    check.names = FALSE
  )


  names(queue)[2] <- id_col


  rownames(queue) <- NULL


  queue
}