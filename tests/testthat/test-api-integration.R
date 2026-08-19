testthat::test_that(
  "Completion Risk API endpoints and input validation work correctly",
  {

    # ============================================================
    # Start API in a background R process
    # ============================================================

    project_dir <- normalizePath(
      testthat::test_path("..", ".."),
      winslash = "/",
      mustWork = TRUE
    )


    port <- 8002


    base_url <- paste0(
      "http://127.0.0.1:",
      port
    )


    api_process <- callr::r_bg(
      func = function(
        project_dir,
        port
      ) {

        setwd(project_dir)


        source("renv/activate.R")
        source("api/plumber.R")


        plumber::pr_run(
          pr = api,
          host = "127.0.0.1",
          port = port
        )
      },
      args = list(
        project_dir = project_dir,
        port = port
      ),
      supervise = TRUE,
      stdout = "|",
      stderr = "|"
    )


    on.exit(
      {

        if (api_process$is_alive()) {

          api_process$kill()
        }
      },
      add = TRUE
    )


    # ============================================================
    # Wait until API is ready
    # ============================================================

    api_ready <- FALSE


    for (attempt in seq_len(40)) {

      Sys.sleep(0.25)


      api_ready <- tryCatch(
        {

          response <- httr2::request(
            paste0(
              base_url,
              "/health"
            )
          ) |>
            httr2::req_timeout(1) |>
            httr2::req_perform()


          httr2::resp_status(response) == 200
        },
        error = function(error) {

          FALSE
        }
      )


      if (api_ready) {

        break
      }


      if (!api_process$is_alive()) {

        break
      }
    }


    if (!api_ready) {

      process_output <- paste(
        api_process$read_all_output(),
        api_process$read_all_error(),
        sep = "\n"
      )


      stop(
        paste(
          "The API did not start successfully.",
          process_output,
          sep = "\n"
        ),
        call. = FALSE
      )
    }


    # ============================================================
    # Internal test helpers
    # ============================================================

    perform_prediction_request <- function(payload) {

      httr2::request(
        paste0(
          base_url,
          "/predict"
        )
      ) |>
        httr2::req_body_json(payload) |>
        httr2::req_timeout(5) |>
        httr2::req_error(
          is_error = function(response) {

            FALSE
          }
        ) |>
        httr2::req_perform()
    }


    expect_bad_request <- function(
      payload,
      expected_error_text
    ) {

      response <- perform_prediction_request(
        payload
      )


      response_status <- httr2::resp_status(
        response
      )


      response_body <- httr2::resp_body_json(
        response,
        simplifyVector = TRUE
      )


      testthat::expect_equal(
        response_status,
        400
      )


      # Prevent a second technical test error if the API
      # unexpectedly returns a response without an error field.
      if (
        response_status != 400 ||
        is.null(response_body$error)
      ) {

        return(
          invisible(response_body)
        )
      }


      testthat::expect_match(
        response_body$error,
        expected_error_text,
        fixed = TRUE
      )


      invisible(response_body)
    }


    expect_valid_prediction_response <- function(
      prediction_body
    ) {

      # ----------------------------------------------------------
      # Exact API response contract
      # ----------------------------------------------------------

      testthat::expect_setequal(
        names(prediction_body),
        c(
          "user_id",
          "completion_probability",
          "completion_risk"
        )
      )


      # ----------------------------------------------------------
      # Deprecated fields must not be exposed
      # ----------------------------------------------------------

      testthat::expect_false(
        "classification_threshold" %in%
          names(prediction_body)
      )


      testthat::expect_false(
        "predicted_completion_status" %in%
          names(prediction_body)
      )


      # ----------------------------------------------------------
      # Probability values
      # ----------------------------------------------------------

      testthat::expect_true(
        is.numeric(
          prediction_body$
            completion_probability
        )
      )


      testthat::expect_true(
        is.numeric(
          prediction_body$
            completion_risk
        )
      )


      testthat::expect_true(
        is.finite(
          prediction_body$
            completion_probability
        )
      )


      testthat::expect_true(
        is.finite(
          prediction_body$
            completion_risk
        )
      )


      testthat::expect_true(
        prediction_body$
          completion_probability >= 0 &&
          prediction_body$
            completion_probability <= 1
      )


      testthat::expect_true(
        prediction_body$
          completion_risk >= 0 &&
          prediction_body$
            completion_risk <= 1
      )


      # ----------------------------------------------------------
      # Probability relationship
      # ----------------------------------------------------------

      testthat::expect_equal(
        prediction_body$
          completion_risk,
        1 -
          prediction_body$
            completion_probability,
        tolerance = 1e-8
      )
    }


    # ============================================================
    # GET /health
    # ============================================================

    health_response <- httr2::request(
      paste0(
        base_url,
        "/health"
      )
    ) |>
      httr2::req_timeout(5) |>
      httr2::req_perform()


    health_body <- httr2::resp_body_json(
      health_response,
      simplifyVector = TRUE
    )


    testthat::expect_equal(
      httr2::resp_status(
        health_response
      ),
      200
    )


    testthat::expect_equal(
      health_body$status,
      "ok"
    )


    testthat::expect_true(
      health_body$model_loaded
    )


    testthat::expect_equal(
      health_body$required_feature_count,
      10
    )


    testthat::expect_equal(
      health_body$observation_window_days,
      10
    )


    # ============================================================
    # Valid prediction request
    # ============================================================

    valid_learner <- list(
      user_id = 1002,
      n_passed_all = 3,
      n_viewed_all = 15,
      n_started_practical = 2,
      n_passed_practical = 1,
      n_submissions = 4,
      submission_correct_rate = 0.25,
      active_days = 3,
      days_since_last_action = 6,
      score_per_active_day = 1,
      steps_per_active_day = 5
    )


    prediction_response <-
      perform_prediction_request(
        valid_learner
      )


    prediction_body <- httr2::resp_body_json(
      prediction_response,
      simplifyVector = TRUE
    )


    testthat::expect_equal(
      httr2::resp_status(
        prediction_response
      ),
      200
    )


    testthat::expect_equal(
      prediction_body$user_id,
      1002
    )


    expect_valid_prediction_response(
      prediction_body
    )


    # ============================================================
    # Valid boundary-value request
    # ============================================================

    boundary_learner <- list(
      user_id = 1,
      n_passed_all = 198,
      n_viewed_all = 198,
      n_started_practical = 76,
      n_passed_practical = 76,
      n_submissions = 76,
      submission_correct_rate = 1,
      active_days = 1,
      days_since_last_action = 9,
      score_per_active_day = 88,
      steps_per_active_day = 198
    )


    boundary_response <-
      perform_prediction_request(
        boundary_learner
      )


    boundary_body <- httr2::resp_body_json(
      boundary_response,
      simplifyVector = TRUE
    )


    testthat::expect_equal(
      httr2::resp_status(
        boundary_response
      ),
      200
    )


    testthat::expect_equal(
      boundary_body$user_id,
      1
    )


    expect_valid_prediction_response(
      boundary_body
    )


    # ============================================================
    # Invalid request: missing feature
    # ============================================================

    missing_feature_learner <-
      valid_learner


    missing_feature_learner$
      active_days <- NULL


    expect_bad_request(
      payload =
        missing_feature_learner,
      expected_error_text =
        "active_days"
    )


    # ============================================================
    # Invalid request: negative learner ID
    # ============================================================

    invalid_user_id_learner <-
      valid_learner


    invalid_user_id_learner$
      user_id <- -1


    expect_bad_request(
      payload =
        invalid_user_id_learner,
      expected_error_text =
        "positive whole number"
    )


    # ============================================================
    # Invalid request: fractional learner ID
    # ============================================================

    fractional_user_id_learner <-
      valid_learner


    fractional_user_id_learner$
      user_id <- 10.5


    expect_bad_request(
      payload =
        fractional_user_id_learner,
      expected_error_text =
        "positive whole number"
    )


    # ============================================================
    # Invalid request:
    # active days outside observation window
    # ============================================================

    invalid_active_days_learner <-
      valid_learner


    invalid_active_days_learner$
      active_days <- 11


    expect_bad_request(
      payload =
        invalid_active_days_learner,
      expected_error_text =
        "active_days"
    )


    # ============================================================
    # Invalid request:
    # submission rate above one
    # ============================================================

    invalid_rate_learner <-
      valid_learner


    invalid_rate_learner$
      submission_correct_rate <- 1.5


    expect_bad_request(
      payload =
        invalid_rate_learner,
      expected_error_text =
        "submission_correct_rate"
    )


    # ============================================================
    # Invalid request:
    # passed-step count above maximum
    # ============================================================

    invalid_passed_count_learner <-
      valid_learner


    invalid_passed_count_learner$
      n_passed_all <- 199


    expect_bad_request(
      payload =
        invalid_passed_count_learner,
      expected_error_text =
        "n_passed_all"
    )


    # ============================================================
    # Invalid request: negative counter
    # ============================================================

    negative_counter_learner <-
      valid_learner


    negative_counter_learner$
      n_submissions <- -1


    expect_bad_request(
      payload =
        negative_counter_learner,
      expected_error_text =
        "n_submissions"
    )


    # ============================================================
    # Invalid request: fractional counter
    # ============================================================

    fractional_counter_learner <-
      valid_learner


    fractional_counter_learner$
      n_viewed_all <- 2.5


    expect_bad_request(
      payload =
        fractional_counter_learner,
      expected_error_text =
        "whole numbers"
    )


    # ============================================================
    # Invalid relationship:
    # passed practical exceeds started practical
    # ============================================================

    invalid_practical_relation <-
      valid_learner


    invalid_practical_relation$
      n_started_practical <- 1


    invalid_practical_relation$
      n_passed_practical <- 2


    expect_bad_request(
      payload =
        invalid_practical_relation,
      expected_error_text =
        "must not exceed `n_started_practical`"
    )


    # ============================================================
    # Invalid relationship:
    # submissions without a started practical step
    # ============================================================

    submissions_without_started <-
      valid_learner


    submissions_without_started$
      n_started_practical <- 0


    submissions_without_started$
      n_passed_practical <- 0


    submissions_without_started$
      n_submissions <- 4


    expect_bad_request(
      payload =
        submissions_without_started,
      expected_error_text =
        "started practical step"
    )


    # ============================================================
    # Invalid relationship:
    # passed practical step without a submission
    # ============================================================

    passed_without_submission <-
      valid_learner


    passed_without_submission$
      n_started_practical <- 2


    passed_without_submission$
      n_passed_practical <- 1


    passed_without_submission$
      n_submissions <- 0


    expect_bad_request(
      payload =
        passed_without_submission,
      expected_error_text =
        "at least one submission"
    )
  }
)