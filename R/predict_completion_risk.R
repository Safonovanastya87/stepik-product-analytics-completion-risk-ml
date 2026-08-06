# Generate completion-risk predictions
predict_completion_risk <- function(
  data,
  loaded_model
) {
  # ============================================================
  # Validate loaded model structure
  # ============================================================

  if (
    !is.list(loaded_model) ||
    is.null(loaded_model$model) ||
    is.null(loaded_model$artifact)
  ) {
    stop(
      "`loaded_model` must be created by load_completion_risk_artifact().",
      call. = FALSE
    )
  }

  if (!inherits(loaded_model$model, "xgb.Booster")) {
    stop(
      "`loaded_model$model` must be an xgb.Booster object.",
      call. = FALSE
    )
  }

  # ============================================================
  # Retrieve inference configuration
  # ============================================================

  feature_cols <- loaded_model$artifact$
    inference_settings$
    feature_cols

  classification_threshold <- loaded_model$artifact$
    inference_settings$
    threshold

  if (
    length(classification_threshold) != 1L ||
    !is.numeric(classification_threshold) ||
    is.na(classification_threshold) ||
    !is.finite(classification_threshold) ||
    classification_threshold < 0 ||
    classification_threshold > 1
  ) {
    stop(
      paste0(
        "The model artifact contains an invalid ",
        "classification threshold."
      ),
      call. = FALSE
    )
  }

  # ============================================================
  # Validate external prediction input
  # ============================================================

  feature_data <- validate_prediction_input(
    data = data,
    feature_cols = feature_cols
  )

  # ============================================================
  # Generate model predictions
  # ============================================================

  prediction_matrix <- data.matrix(
    feature_data
  )

  completion_probability <- as.numeric(
    predict(
      loaded_model$model,
      prediction_matrix
    )
  )

  # ============================================================
  # Validate model output
  # ============================================================

  if (
    length(completion_probability) != nrow(feature_data) ||
    anyNA(completion_probability) ||
    any(!is.finite(completion_probability))
  ) {
    stop(
      "The model returned invalid predictions.",
      call. = FALSE
    )
  }

  if (
    any(completion_probability < 0) ||
    any(completion_probability > 1)
  ) {
    stop(
      "Predicted probabilities must be between 0 and 1.",
      call. = FALSE
    )
  }

  # ============================================================
  # Calculate diagnostic prediction status
  # ============================================================

  predicted_completion_status <- ifelse(
    completion_probability >= classification_threshold,
    "Predicted_Completed",
    "Predicted_Not_Completed"
  )

  # ============================================================
  # Build prediction result
  # ============================================================

  result <- data

  result$completion_probability <-
    completion_probability

  result$completion_risk <-
    1 - completion_probability

  result$classification_threshold <-
    classification_threshold

  result$predicted_completion_status <-
    predicted_completion_status

  result
}