project_root <- testthat::test_path(
  "..",
  ".."
)


# ============================================================
# Load project functions
# ============================================================

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

source(
  file.path(
    project_root,
    "R",
    "batch_scoring.R"
  )
)


# ============================================================
# Load the trained model artifact
# ============================================================

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


# ============================================================
# Create one valid learner for unit tests
# ============================================================

valid_test_data <- as.data.frame(
  matrix(
    0,
    nrow = 1,
    ncol = length(feature_cols)
  )
)

names(valid_test_data) <- feature_cols


valid_test_data$n_passed_all <- 3
valid_test_data$n_viewed_all <- 15
valid_test_data$n_started_practical <- 2
valid_test_data$n_passed_practical <- 1
valid_test_data$n_submissions <- 4
valid_test_data$submission_correct_rate <- 0.25
valid_test_data$active_days <- 3
valid_test_data$days_since_last_action <- 6
valid_test_data$score_per_active_day <- 1
valid_test_data$steps_per_active_day <- 1

valid_test_data$user_id <- 1001