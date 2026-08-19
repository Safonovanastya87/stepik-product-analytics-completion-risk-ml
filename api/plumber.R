# Completion Risk Prediction API

source("R/load_artifact.R")
source("R/validate_prediction_input.R")
source("R/predict_completion_risk.R")
source("R/build_retention_queue.R")


# ============================================================
# Load model once when the API starts
# ============================================================

loaded_model <- load_completion_risk_artifact()


# ============================================================
# Internal helpers
# ============================================================

request_records_to_data_frame <- function(records) {

  if (is.data.frame(records)) {

    return(
      as.data.frame(
        records,
        stringsAsFactors = FALSE
      )
    )
  }


  if (
    is.list(records) &&
    length(records) > 0L &&
    all(
      vapply(
        records,
        is.list,
        logical(1)
      )
    )
  ) {

    rows <- lapply(
      records,
      function(record) {

        as.data.frame(
          record,
          stringsAsFactors = FALSE
        )
      }
    )


    return(
      do.call(
        rbind,
        rows
      )
    )
  }


  if (
    is.list(records) &&
    !is.null(names(records))
  ) {

    return(
      as.data.frame(
        records,
        stringsAsFactors = FALSE
      )
    )
  }


  stop(
    paste(
      "Learner data must be a JSON object",
      "or an array of JSON objects."
    ),
    call. = FALSE
  )
}


validate_and_normalize_user_ids <- function(data) {

  if (!"user_id" %in% names(data)) {

    stop(
      "Missing required field: user_id",
      call. = FALSE
    )
  }


  user_ids <- data[["user_id"]]


  if (is.list(user_ids)) {

    user_ids <- unlist(
      user_ids,
      recursive = TRUE,
      use.names = FALSE
    )
  }


  valid_user_ids <- (
    length(user_ids) == nrow(data) &&
      is.numeric(user_ids) &&
      !anyNA(user_ids) &&
      all(is.finite(user_ids)) &&
      all(user_ids > 0) &&
      all(
        abs(
          user_ids - round(user_ids)
        ) <= sqrt(.Machine$double.eps)
      )
  )


  if (!isTRUE(valid_user_ids)) {

    stop(
      paste(
        "`user_id` must contain one positive",
        "whole number per learner."
      ),
      call. = FALSE
    )
  }


  duplicate_rows <- which(
    duplicated(user_ids) |
      duplicated(
        user_ids,
        fromLast = TRUE
      )
  )


  if (length(duplicate_rows) > 0L) {

    stop(
      paste0(
        "`user_id` must be unique within a batch. ",
        "Duplicate row(s): ",
        paste(
          duplicate_rows,
          collapse = ", "
        ),
        "."
      ),
      call. = FALSE
    )
  }


  data$user_id <- as.numeric(
    round(user_ids)
  )


  data
}


validate_top_n <- function(
  top_n,
  learner_count
) {

  valid_top_n <- (
    length(top_n) == 1L &&
      is.numeric(top_n) &&
      !is.na(top_n) &&
      is.finite(top_n) &&
      top_n > 0 &&
      abs(
        top_n - round(top_n)
      ) <= sqrt(.Machine$double.eps)
  )


  if (!isTRUE(valid_top_n)) {

    stop(
      "`top_n` must be one positive whole number.",
      call. = FALSE
    )
  }


  top_n <- as.integer(
    round(top_n)
  )


  if (top_n > learner_count) {

    stop(
      paste0(
        "`top_n` cannot exceed the number of ",
        "learners in the batch (",
        learner_count,
        ")."
      ),
      call. = FALSE
    )
  }


  top_n
}


data_frame_to_records <- function(data) {

  if (
    !is.data.frame(data) ||
    nrow(data) == 0L
  ) {

    return(
      list()
    )
  }


  lapply(
    seq_len(nrow(data)),
    function(row_number) {

      row <- data[
        row_number,
        ,
        drop = FALSE
      ]


      lapply(
        row,
        function(column) {

          column[[1]]
        }
      )
    }
  )
}


clean_prediction_output <- function(predictions) {

  deprecated_columns <- c(
    "classification_threshold",
    "predicted_completion_status"
  )


  predictions[
    ,
    setdiff(
      names(predictions),
      deprecated_columns
    ),
    drop = FALSE
  ]
}


clean_queue_output <- function(
  retention_queue,
  id_col = "user_id"
) {

  required_columns <- c(
    "risk_rank",
    id_col,
    "completion_risk",
    "completion_probability"
  )


  missing_columns <- setdiff(
    required_columns,
    names(retention_queue)
  )


  if (length(missing_columns) > 0L) {

    stop(
      paste0(
        "Priority queue is missing required column(s): ",
        paste(
          missing_columns,
          collapse = ", "
        ),
        "."
      ),
      call. = FALSE
    )
  }


  retention_queue[
    ,
    required_columns,
    drop = FALSE
  ]
}


# ============================================================
# Create API router
# ============================================================

api <- plumber::pr()


# Accept JSON request bodies

api <- plumber::pr_set_parsers(
  pr = api,
  parsers = "json"
)


# Return scalar values instead of one-element JSON arrays

api <- plumber::pr_set_serializer(
  pr = api,
  serializer =
    plumber::serializer_unboxed_json()
)


# ============================================================
# GET /health
# ============================================================

api <- plumber::pr_get(
  pr = api,
  path = "/health",
  handler = function() {

    feature_cols <-
      loaded_model$artifact$
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
# Single-learner risk prediction
# ============================================================

api <- plumber::pr_post(
  pr = api,
  path = "/predict",
  handler = function(req, res) {

    request_body <- req$body


    if (is.null(request_body)) {

      res$status <- 400


      return(
        list(
          error =
            "JSON request body is required."
        )
      )
    }


    tryCatch(
      {

        prediction_input <-
          request_records_to_data_frame(
            request_body
          )


        if (nrow(prediction_input) != 1L) {

          stop(
            paste(
              "The request body must describe",
              "exactly one learner."
            ),
            call. = FALSE
          )
        }


        prediction_input <-
          validate_and_normalize_user_ids(
            prediction_input
          )


        prediction_raw <-
          predict_completion_risk(
            data = prediction_input,
            loaded_model = loaded_model
          )


        prediction <-
          clean_prediction_output(
            prediction_raw
          )


        if (
          !"completion_probability" %in%
            names(prediction) ||
          !"completion_risk" %in%
            names(prediction)
        ) {

          stop(
            paste(
              "Prediction output must contain",
              "`completion_probability` and",
              "`completion_risk`."
            ),
            call. = FALSE
          )
        }


        completion_probability <-
          as.numeric(
            prediction$
              completion_probability[[1]]
          )


        completion_risk <-
          as.numeric(
            prediction$
              completion_risk[[1]]
          )


        if (
          !is.finite(completion_probability) ||
          completion_probability < 0 ||
          completion_probability > 1 ||
          !is.finite(completion_risk) ||
          completion_risk < 0 ||
          completion_risk > 1
        ) {

          stop(
            paste(
              "Prediction probabilities must",
              "be between 0 and 1."
            ),
            call. = FALSE
          )
        }


        list(
          user_id =
            prediction$user_id[[1]],

          completion_probability =
            completion_probability,

          completion_risk =
            completion_risk
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


# ============================================================
# POST /predict-batch
# Capacity-based prioritization
# ============================================================

api <- plumber::pr_post(
  pr = api,
  path = "/predict-batch",
  handler = function(req, res) {

    request_body <- req$body


    if (is.null(request_body)) {

      res$status <- 400


      return(
        list(
          error =
            "JSON request body is required."
        )
      )
    }


    if (
      !is.list(request_body) ||
      is.null(request_body$learners)
    ) {

      res$status <- 400


      return(
        list(
          error = paste(
            "The request body must contain",
            "a `learners` array."
          )
        )
      )
    }


    if (is.null(request_body$top_n)) {

      res$status <- 400


      return(
        list(
          error = paste(
            "The request body must contain",
            "a `top_n` value."
          )
        )
      )
    }


    tryCatch(
      {

        # --------------------------------------------------------
        # Convert request data
        # --------------------------------------------------------

        batch_input <-
          request_records_to_data_frame(
            request_body$learners
          )


        if (nrow(batch_input) == 0L) {

          stop(
            paste(
              "`learners` must contain",
              "at least one learner."
            ),
            call. = FALSE
          )
        }


        # --------------------------------------------------------
        # Validate learner IDs
        # --------------------------------------------------------

        batch_input <-
          validate_and_normalize_user_ids(
            batch_input
          )


        # --------------------------------------------------------
        # Validate intervention capacity
        # --------------------------------------------------------

        top_n <- validate_top_n(
          top_n = request_body$top_n,
          learner_count = nrow(batch_input)
        )


        # --------------------------------------------------------
        # Score all learners
        # --------------------------------------------------------

        predictions_raw <-
          predict_completion_risk(
            data = batch_input,
            loaded_model = loaded_model
          )


        # --------------------------------------------------------
        # Build Top-N priority queue
        # --------------------------------------------------------

        retention_queue_raw <-
          build_retention_queue(
            predictions = predictions_raw,
            id_col = "user_id",
            top_n = top_n
          )


        # --------------------------------------------------------
        # Remove deprecated classification output
        # --------------------------------------------------------

        predictions <-
          clean_prediction_output(
            predictions_raw
          )


        retention_queue <-
          clean_queue_output(
            retention_queue_raw,
            id_col = "user_id"
          )


        # --------------------------------------------------------
        # Validate probability ranges
        # --------------------------------------------------------

        if (
          !"completion_probability" %in%
            names(predictions) ||
          !"completion_risk" %in%
            names(predictions)
        ) {

          stop(
            paste(
              "Prediction output must contain",
              "`completion_probability` and",
              "`completion_risk`."
            ),
            call. = FALSE
          )
        }


        completion_probabilities <-
          as.numeric(
            predictions$
              completion_probability
          )


        completion_risks <-
          as.numeric(
            predictions$
              completion_risk
          )


        valid_probabilities <- (
          all(
            is.finite(
              completion_probabilities
            )
          ) &&
          all(
            completion_probabilities >= 0 &
              completion_probabilities <= 1
          ) &&
          all(
            is.finite(
              completion_risks
            )
          ) &&
          all(
            completion_risks >= 0 &
              completion_risks <= 1
          )
        )


        if (!isTRUE(valid_probabilities)) {

          stop(
            paste(
              "Prediction probabilities must",
              "be between 0 and 1."
            ),
            call. = FALSE
          )
        }


        # --------------------------------------------------------
        # Response
        # --------------------------------------------------------

        list(
          learner_count =
            nrow(predictions),

          queue_count =
            nrow(retention_queue),

          top_n =
            top_n,

          predictions =
            data_frame_to_records(
              predictions
            ),

          retention_queue =
            data_frame_to_records(
              retention_queue
            )
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