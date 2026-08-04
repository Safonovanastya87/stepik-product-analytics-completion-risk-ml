# Run completion-risk scoring for a CSV file
run_batch_scoring <- function(
  input_path,
  predictions_output_path,
  queue_output_path,
  artifact_path = "artifacts/completion_risk_artifact.rds",
  id_col = "user_id",
  min_risk = 0.5,
  top_n = NULL
) {
  if (!file.exists(input_path)) {
    stop(
      "Input file does not exist: ",
      input_path,
      call. = FALSE
    )
  }

  learner_data <- read.csv(
    input_path,
    stringsAsFactors = FALSE
  )

  loaded_model <- load_completion_risk_artifact(
    path = artifact_path
  )

  predictions <- predict_completion_risk(
    data = learner_data,
    loaded_model = loaded_model
  )

  retention_queue <- build_retention_queue(
    predictions = predictions,
    id_col = id_col,
    min_risk = min_risk,
    top_n = top_n
  )

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

  write.csv(
    predictions,
    predictions_output_path,
    row.names = FALSE
  )

  write.csv(
    retention_queue,
    queue_output_path,
    row.names = FALSE
  )

  list(
    predictions = predictions,
    retention_queue = retention_queue,
    predictions_output_path =
      predictions_output_path,
    queue_output_path =
      queue_output_path
  )
}