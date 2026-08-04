testthat::test_that(
  "Completion Risk API endpoints work correctly",
  {
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

    api_ready <- FALSE

    for (attempt in seq_len(40)) {
      Sys.sleep(0.25)

      api_ready <- tryCatch(
        {
          response <- httr2::request(
            paste0(base_url, "/health")
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

    health_response <- httr2::request(
      paste0(base_url, "/health")
    ) |>
      httr2::req_perform()

    health_body <- httr2::resp_body_json(
      health_response,
      simplifyVector = TRUE
    )

    testthat::expect_equal(
      httr2::resp_status(health_response),
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

    prediction_response <- httr2::request(
      paste0(base_url, "/predict")
    ) |>
      httr2::req_body_json(
        valid_learner
      ) |>
      httr2::req_perform()

    prediction_body <- httr2::resp_body_json(
      prediction_response,
      simplifyVector = TRUE
    )

    testthat::expect_equal(
      httr2::resp_status(prediction_response),
      200
    )

    testthat::expect_equal(
      prediction_body$user_id,
      1002
    )

    testthat::expect_true(
      prediction_body$completion_probability >= 0
    )

    testthat::expect_true(
      prediction_body$completion_probability <= 1
    )

    testthat::expect_equal(
      prediction_body$completion_risk,
      1 - prediction_body$completion_probability,
      tolerance = 1e-8
    )

    invalid_learner <- valid_learner
    invalid_learner$active_days <- NULL

    invalid_response <- httr2::request(
      paste0(base_url, "/predict")
    ) |>
      httr2::req_body_json(
        invalid_learner
      ) |>
      httr2::req_error(
        is_error = function(response) {
          FALSE
        }
      ) |>
      httr2::req_perform()

    invalid_body <- httr2::resp_body_json(
      invalid_response,
      simplifyVector = TRUE
    )

    testthat::expect_equal(
      httr2::resp_status(invalid_response),
      400
    )

    testthat::expect_match(
      invalid_body$error,
      "active_days"
    )
  }
)