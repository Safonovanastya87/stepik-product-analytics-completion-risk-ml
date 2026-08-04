# Validate and prepare input data for model prediction
validate_prediction_input <- function(
  data,
  feature_cols
) {
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

  feature_data <- data[
    ,
    feature_cols,
    drop = FALSE
  ]

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

  feature_data
}