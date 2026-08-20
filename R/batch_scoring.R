# Run batch completion-risk scoring for an XLSX file

run_batch_scoring <- function(
  input_path,
  predictions_output_path,
  queue_output_path,
  artifact_path =
    "artifacts/completion_risk_artifact.rds",
  id_col = "user_id",
  top_n = NULL
) {

  # ============================================================
  # Validate file paths
  # ============================================================

  if (
    length(input_path) != 1L ||
    !is.character(input_path) ||
    is.na(input_path) ||
    !nzchar(input_path)
  ) {

    stop(
      "`input_path` must be one non-empty file path.",
      call. = FALSE
    )
  }


  if (!file.exists(input_path)) {

    stop(
      paste0(
        "Input file does not exist: ",
        input_path
      ),
      call. = FALSE
    )
  }


  if (
    length(predictions_output_path) != 1L ||
    !is.character(predictions_output_path) ||
    is.na(predictions_output_path) ||
    !nzchar(predictions_output_path)
  ) {

    stop(
      paste(
        "`predictions_output_path` must be",
        "one non-empty file path."
      ),
      call. = FALSE
    )
  }


  if (
    length(queue_output_path) != 1L ||
    !is.character(queue_output_path) ||
    is.na(queue_output_path) ||
    !nzchar(queue_output_path)
  ) {

    stop(
      paste(
        "`queue_output_path` must be",
        "one non-empty file path."
      ),
      call. = FALSE
    )
  }


  # ============================================================
  # Read learner data
  # ============================================================

  learner_data <- readxl::read_excel(
    input_path
  )


  learner_data <- as.data.frame(
    learner_data,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )


  if (nrow(learner_data) == 0L) {

    stop(
      "The input XLSX contains no learners.",
      call. = FALSE
    )
  }


  if (!id_col %in% names(learner_data)) {

    stop(
      paste0(
        "Missing required identifier column: ",
        id_col,
        "."
      ),
      call. = FALSE
    )
  }


  # ============================================================
  # Load trained model
  # ============================================================

  loaded_model <-
    load_completion_risk_artifact(
      path = artifact_path
    )


  # ============================================================
  # Generate predictions
  # ============================================================

  predictions_raw <-
    predict_completion_risk(
      data = learner_data,
      loaded_model = loaded_model
    )


  required_prediction_cols <- c(
    "completion_probability",
    "completion_risk"
  )


  missing_prediction_cols <- setdiff(
    required_prediction_cols,
    names(predictions_raw)
  )


  if (length(missing_prediction_cols) > 0L) {

    stop(
      paste0(
        "Prediction output is missing required column(s): ",
        paste(
          missing_prediction_cols,
          collapse = ", "
        ),
        "."
      ),
      call. = FALSE
    )
  }


  # ============================================================
  # Build strict prediction output
  # ============================================================

  prediction_output_cols <- c(
    names(learner_data),
    "completion_probability",
    "completion_risk"
  )


  predictions <- predictions_raw[
    ,
    prediction_output_cols,
    drop = FALSE
  ]


  # ============================================================
  # Validate probability output
  # ============================================================

  completion_probability <-
    predictions$completion_probability


  completion_risk <-
    predictions$completion_risk


  valid_probabilities <- (
    is.numeric(completion_probability) &&
      is.numeric(completion_risk) &&
      !anyNA(completion_probability) &&
      !anyNA(completion_risk) &&
      all(is.finite(completion_probability)) &&
      all(is.finite(completion_risk)) &&
      all(
        completion_probability >= 0 &
          completion_probability <= 1
      ) &&
      all(
        completion_risk >= 0 &
          completion_risk <= 1
      )
  )


  if (!isTRUE(valid_probabilities)) {

    stop(
      paste(
        "`completion_probability` and",
        "`completion_risk` must contain",
        "numeric values between 0 and 1."
      ),
      call. = FALSE
    )
  }


  inconsistent_rows <- which(
    abs(
      completion_risk -
        (1 - completion_probability)
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
  # Resolve prioritization capacity
  # ============================================================

  if (is.null(top_n)) {

    top_n <- nrow(predictions)
  }


  # ============================================================
  # Build priority intervention queue
  # ============================================================

  retention_queue <-
    build_retention_queue(
      predictions = predictions,
      id_col = id_col,
      top_n = top_n
    )


  expected_queue_cols <- c(
    "risk_rank",
    id_col,
    "completion_probability",
    "completion_risk"
  )


  if (
    !identical(
      names(retention_queue),
      expected_queue_cols
    )
  ) {

    stop(
      paste(
        "Priority queue output does not",
        "match the expected column structure."
      ),
      call. = FALSE
    )
  }


  # ============================================================
  # Create output directories
  # ============================================================

  output_dirs <- unique(
    c(
      dirname(predictions_output_path),
      dirname(queue_output_path)
    )
  )


  for (output_dir in output_dirs) {

    if (
      output_dir != "." &&
      !dir.exists(output_dir)
    ) {

      dir.create(
        output_dir,
        recursive = TRUE
      )
    }
  }


  # ============================================================
  # Save prediction results
  # ============================================================

  writexl::write_xlsx(
    predictions,
    predictions_output_path
  )


  # ============================================================
  # Save priority queue
  # ============================================================

  writexl::write_xlsx(
    retention_queue,
    queue_output_path
  )


  # ============================================================
  # Return results
  # ============================================================

  list(
    predictions =
      predictions,

    retention_queue =
      retention_queue,

    predictions_output_path =
      predictions_output_path,

    queue_output_path =
      queue_output_path
  )
}