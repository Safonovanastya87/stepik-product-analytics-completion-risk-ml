## Completion Risk Prediction API

source("R/load_artifact.R")
source("R/validate_prediction_input.R")
source("R/predict_completion_risk.R")
source("R/build_retention_queue.R")


# Load the model once when the API starts
loaded_model <- load_completion_risk_artifact()


# Create an empty API router
api <- plumber::pr()


# Accept JSON request bodies
api <- plumber::pr_set_parsers(
  pr = api,
  parsers = "json"
)


# Return single values without one-element JSON arrays
api <- plumber::pr_set_serializer(
  pr = api,
  serializer = plumber::serializer_unboxed_json()
)


# ============================================================
# GET /health
# ============================================================

api <- plumber::pr_get(
  pr = api,
  path = "/health",
  handler = function() {
    feature_cols <- loaded_model$artifact$
      inference_settings$
      feature_cols

    list(
      status = "ok",
      model_loaded = TRUE,
      model_class = class(
        loaded_model$model
      )[1],
      required_feature_count = length(
        feature_cols
      ),
      observation_window_days =
        loaded_model$artifact$
        model_metadata$
        observation_window_days
    )
  }
)


# ============================================================
# POST /predict
# ============================================================

api <- plumber::pr_post(
  pr = api,
  path = "/predict",
  handler = function(req, res) {
    # ----------------------------------------------------------
    # Validate request body
    # ----------------------------------------------------------

    request_body <- req$body

    if (is.null(request_body)) {
      res$status <- 400

      return(
        list(
          error = "JSON request body is required."
        )
      )
    }

    # ----------------------------------------------------------
    # Convert JSON request to a one-row data frame
    # ----------------------------------------------------------

    prediction_input <- tryCatch(
      as.data.frame(
        request_body,
        stringsAsFactors = FALSE
      ),
      error = function(error) {
        NULL
      }
    )

    if (
      is.null(prediction_input) ||
      nrow(prediction_input) != 1L
    ) {
      res$status <- 400

      return(
        list(
          error = paste(
            "The request body must describe",
            "exactly one learner."
          )
        )
      )
    }

    # ----------------------------------------------------------
    # Validate learner identifier
    # ----------------------------------------------------------

    if (!"user_id" %in% names(prediction_input)) {
      res$status <- 400

      return(
        list(
          error = "Missing required field: user_id"
        )
      )
    }

    user_id_column <- prediction_input[["user_id"]]

    if (length(user_id_column) != 1L) {
      res$status <- 400

      return(
        list(
          error = "`user_id` must contain exactly one value."
        )
      )
    }

    # Depending on JSON conversion, a value may appear
    # as a regular vector or as a list-column.
    user_id <- if (is.list(user_id_column)) {
      user_id_column[[1]]
    } else {
      user_id_column[[1]]
    }

    valid_user_id <- (
      length(user_id) == 1L &&
        is.numeric(user_id) &&
        !is.na(user_id) &&
        is.finite(user_id) &&
        user_id > 0 &&
        abs(user_id - round(user_id)) <=
          sqrt(.Machine$double.eps)
    )

    if (!isTRUE(valid_user_id)) {
      res$status <- 400

      return(
        list(
          error = "`user_id` must be a positive whole number."
        )
      )
    }

    prediction_input$user_id <- as.numeric(
      user_id
    )

    # ----------------------------------------------------------
    # Validate model features and generate prediction
    # ----------------------------------------------------------

    tryCatch(
      {
        prediction <- predict_completion_risk(
          data = prediction_input,
          loaded_model = loaded_model
        )

        list(
          user_id =
            prediction$user_id[[1]],

          completion_probability =
            prediction$completion_probability[[1]],

          completion_risk =
            prediction$completion_risk[[1]],

          classification_threshold =
            prediction$classification_threshold[[1]],

          predicted_completion_status =
            prediction$predicted_completion_status[[1]]
        )
      },
      error = function(error) {
        res$status <- 400

        list(
          error = conditionMessage(error)
        )
      }
    )
  }
)