# Build a ranked queue of students with high non-completion risk
build_retention_queue <- function(
  predictions,
  id_col = "user_id",
  min_risk = 0.5,
  top_n = NULL
) {
  if (!is.data.frame(predictions)) {
    stop(
      "`predictions` must be a data frame.",
      call. = FALSE
    )
  }

  if (nrow(predictions) == 0) {
    stop(
      "`predictions` must contain at least one row.",
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

  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  if (
    length(min_risk) != 1 ||
    !is.numeric(min_risk) ||
    is.na(min_risk) ||
    min_risk < 0 ||
    min_risk > 1
  ) {
    stop(
      "`min_risk` must be one number between 0 and 1.",
      call. = FALSE
    )
  }

  if (
    !is.null(top_n) &&
    (
      length(top_n) != 1 ||
      !is.numeric(top_n) ||
      is.na(top_n) ||
      top_n < 1 ||
      top_n != as.integer(top_n)
    )
  ) {
    stop(
      "`top_n` must be NULL or a positive integer.",
      call. = FALSE
    )
  }

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
      setdiff(names(queue), first_cols)
    ),
    drop = FALSE
  ]

  rownames(queue) <- NULL

  queue
}