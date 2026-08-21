# Run batch completion-risk scoring


source("R/load_artifact.R")
source("R/validate_prediction_input.R")
source("R/predict_completion_risk.R")
source("R/build_retention_queue.R")
source("R/batch_scoring.R")


batch_result <- run_batch_scoring(
  input_path = "data/demo_batch_learners.xlsx",
  predictions_output_path =
    "outputs/completion_risk_predictions.xlsx",
  queue_output_path =
    "outputs/retention_queue.xlsx",
  top_n = 20L
)


message("Batch scoring completed.")

message(
  "Predictions saved to: ",
  batch_result$predictions_output_path
)

message(
  "Retention queue saved to: ",
  batch_result$queue_output_path
)