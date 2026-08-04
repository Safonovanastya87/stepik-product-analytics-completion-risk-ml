project_root <- testthat::test_path(
  "..",
  ".."
)

source(
  file.path(
    project_root,
    "R",
    "load_artifact.R"
  )
)

source(
  file.path(
    project_root,
    "R",
    "validate_prediction_input.R"
  )
)

source(
  file.path(
    project_root,
    "R",
    "predict_completion_risk.R"
  )
)

source(
  file.path(
    project_root,
    "R",
    "build_retention_queue.R"
  )
)

loaded_model <- load_completion_risk_artifact(
  path = file.path(
    project_root,
    "artifacts",
    "completion_risk_artifact.rds"
  )
)

feature_cols <- loaded_model$artifact$
  inference_settings$
  feature_cols

valid_test_data <- as.data.frame(
  matrix(
    0,
    nrow = 1,
    ncol = length(feature_cols)
  )
)

names(valid_test_data) <- feature_cols
valid_test_data$user_id <- 1001