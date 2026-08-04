# Generate completion-risk predictions
predict_completion_risk <- function(
  data,
  loaded_model
) {
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

  feature_cols <- loaded_model$artifact$
    inference_settings$
    feature_cols

  feature_data <- validate_prediction_input(
    data = data,
    feature_cols = feature_cols
  )

  prediction_matrix <- data.matrix(
    feature_data
  )

  completion_probability <- as.numeric(
    predict(
      loaded_model$model,
      prediction_matrix
    )
  )

  if (
    length(completion_probability) != nrow(data) ||
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

  result <- data

  result$completion_probability <-
    completion_probability

  result$completion_risk <-
    1 - completion_probability

  result
}