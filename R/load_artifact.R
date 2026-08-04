# Load and validate the completion-risk model artifact
load_completion_risk_artifact <- function(
  path = "artifacts/completion_risk_artifact.rds"
) {
  if (!file.exists(path)) {
    stop(
      "Artifact file does not exist: ",
      path,
      call. = FALSE
    )
  }

  artifact <- readRDS(path)

  required_sections <- c(
    "model_metadata",
    "model_raw",
    "inference_settings"
  )

  missing_sections <- setdiff(
    required_sections,
    names(artifact)
  )

  if (length(missing_sections) > 0) {
    stop(
      "Artifact is missing required sections: ",
      paste(missing_sections, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.raw(artifact$model_raw)) {
    stop(
      "artifact$model_raw must be a raw vector.",
      call. = FALSE
    )
  }

  model <- xgboost::xgb.load.raw(
    artifact$model_raw
  )

  list(
    artifact = artifact,
    model = model,
    path = normalizePath(
      path,
      winslash = "/"
    )
  )
}