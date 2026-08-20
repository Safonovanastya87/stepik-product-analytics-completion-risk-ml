testthat::test_that(
  "Batch prediction API works correctly",
  {

    # ============================================================
    # Start API in a background process
    # ============================================================

    project_dir <- normalizePath(
      testthat::test_path("..", ".."),
      winslash = "/",
      mustWork = TRUE
    )


    port <- 8003


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
    # Request helper
    # ============================================================

    perform_batch_request <- function(payload) {

      httr2::request(
        paste0(
          base_url,
          "/predict-batch"
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


    # ============================================================
    # Valid batch payload
    # ============================================================

    learners <- list(
      list(
        user_id = 1001,
        n_passed_all = 0,
        n_viewed_all = 5,
        n_started_practical = 0,
        n_passed_practical = 0,
        n_submissions = 0,
        submission_correct_rate = 0,
        active_days = 1,
        days_since_last_action = 9,
        score_per_active_day = 0,
        steps_per_active_day = 5
      ),
      list(
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
      ),
      list(
        user_id = 1004,
        n_passed_all = 25,
        n_viewed_all = 55,
        n_started_practical = 20,
        n_passed_practical = 18,
        n_submissions = 28,
        submission_correct_rate = 0.64,
        active_days = 9,
        days_since_last_action = 1,
        score_per_active_day = 2.78,
        steps_per_active_day = 6.11
      )
    )


    valid_payload <- list(
      learners = learners,
      top_n = 2
    )


    batch_response <- perform_batch_request(
      valid_payload
    )


    batch_body <- httr2::resp_body_json(
      batch_response,
      simplifyVector = FALSE
    )


    # ============================================================
    # Response status and counts
    # ============================================================

    testthat::expect_equal(
      httr2::resp_status(
        batch_response
      ),
      200
    )


    testthat::expect_equal(
      batch_body$learner_count,
      3
    )


    testthat::expect_equal(
      batch_body$queue_count,
      2
    )


    testthat::expect_equal(
      batch_body$top_n,
      2
    )


    testthat::expect_equal(
      length(
        batch_body$predictions
      ),
      3
    )


    testthat::expect_equal(
      length(
        batch_body$retention_queue
      ),
      2
    )


    # ============================================================
    # Prediction output contract
    # ============================================================

    input_columns <- names(
      learners[[1]]
    )


    expected_prediction_columns <- c(
      input_columns,
      "completion_probability",
      "completion_risk"
    )


    for (prediction in batch_body$predictions) {

      testthat::expect_setequal(
        names(prediction),
        expected_prediction_columns
      )


      testthat::expect_false(
        "classification_threshold" %in%
          names(prediction)
      )


      testthat::expect_false(
        "predicted_completion_status" %in%
          names(prediction)
      )


      testthat::expect_true(
        is.numeric(
          prediction$completion_probability
        )
      )


      testthat::expect_true(
        is.numeric(
          prediction$completion_risk
        )
      )


      testthat::expect_true(
        is.finite(
          prediction$completion_probability
        )
      )


      testthat::expect_true(
        is.finite(
          prediction$completion_risk
        )
      )


      testthat::expect_true(
        prediction$completion_probability >= 0 &&
          prediction$completion_probability <= 1
      )


      testthat::expect_true(
        prediction$completion_risk >= 0 &&
          prediction$completion_risk <= 1
      )


      testthat::expect_equal(
        prediction$completion_risk,
        1 - prediction$completion_probability,
        tolerance = 1e-8
      )
    }


    # ============================================================
    # Priority queue output contract
    # ============================================================

    expected_queue_columns <- c(
      "risk_rank",
     "user_id",
     "completion_probability",
     "completion_risk"
    )


    for (queue_entry in batch_body$retention_queue) {

      testthat::expect_setequal(
        names(queue_entry),
        expected_queue_columns
      )


      testthat::expect_false(
        "classification_threshold" %in%
          names(queue_entry)
      )


      testthat::expect_false(
        "predicted_completion_status" %in%
          names(queue_entry)
      )


      testthat::expect_true(
        queue_entry$completion_probability >= 0 &&
          queue_entry$completion_probability <= 1
      )


      testthat::expect_true(
        queue_entry$completion_risk >= 0 &&
          queue_entry$completion_risk <= 1
      )


      testthat::expect_equal(
        queue_entry$completion_risk,
        1 - queue_entry$completion_probability,
        tolerance = 1e-8
      )
    }


    # ============================================================
    # Priority ranking
    # ============================================================

    queue_ranks <- vapply(
      batch_body$retention_queue,
      function(entry) {

        as.integer(
          entry$risk_rank
        )
      },
      integer(1)
    )


    queue_risks <- vapply(
      batch_body$retention_queue,
      function(entry) {

        as.numeric(
          entry$completion_risk
        )
      },
      numeric(1)
    )


    testthat::expect_equal(
      queue_ranks,
      seq_len(
        length(
          batch_body$retention_queue
        )
      )
    )


    testthat::expect_true(
      all(
        diff(queue_risks) <= 0
      )
    )


    # ============================================================
    # Expected Top-N learners
    # ============================================================

    prediction_ids <- vapply(
      batch_body$predictions,
      function(entry) {

        as.numeric(
          entry$user_id
        )
      },
      numeric(1)
    )


    prediction_risks <- vapply(
      batch_body$predictions,
      function(entry) {

        as.numeric(
          entry$completion_risk
        )
      },
      numeric(1)
    )


    expected_order <- order(
      -prediction_risks,
      seq_along(prediction_risks)
    )


    expected_top_ids <- prediction_ids[
      head(
        expected_order,
        2
      )
    ]


    actual_top_ids <- vapply(
      batch_body$retention_queue,
      function(entry) {

        as.numeric(
          entry$user_id
        )
      },
      numeric(1)
    )


    testthat::expect_equal(
      actual_top_ids,
      expected_top_ids
    )


    # ============================================================
    # Invalid batch:
    # one learner has invalid active_days
    # ============================================================

    invalid_learners <- learners


    invalid_learners[[2]]$
      active_days <- 11


    invalid_payload <- list(
      learners = invalid_learners,
      top_n = 2
    )


    invalid_response <- perform_batch_request(
      invalid_payload
    )


    invalid_body <- httr2::resp_body_json(
      invalid_response,
      simplifyVector = TRUE
    )


    testthat::expect_equal(
      httr2::resp_status(
        invalid_response
      ),
      400
    )


    testthat::expect_match(
      invalid_body$error,
      "active_days",
      fixed = TRUE
    )


    # ============================================================
    # Invalid batch:
    # duplicate user IDs
    # ============================================================

    duplicate_learners <- learners


    duplicate_learners[[2]]$
      user_id <- 1001


    duplicate_payload <- list(
      learners = duplicate_learners,
      top_n = 2
    )


    duplicate_response <- perform_batch_request(
      duplicate_payload
    )


    duplicate_body <- httr2::resp_body_json(
      duplicate_response,
      simplifyVector = TRUE
    )


    testthat::expect_equal(
      httr2::resp_status(
        duplicate_response
      ),
      400
    )


    testthat::expect_match(
      duplicate_body$error,
      "unique within a batch",
      fixed = TRUE
    )


    # ============================================================
    # Invalid request:
    # missing learners array
    # ============================================================

    missing_learners_response <-
      perform_batch_request(
        list(
          top_n = 2
        )
      )


    missing_learners_body <-
      httr2::resp_body_json(
        missing_learners_response,
        simplifyVector = TRUE
      )


    testthat::expect_equal(
      httr2::resp_status(
        missing_learners_response
      ),
      400
    )


    testthat::expect_match(
      missing_learners_body$error,
      "learners",
      fixed = TRUE
    )


    # ============================================================
    # Invalid request:
    # missing top_n
    # ============================================================

    missing_top_n_response <-
      perform_batch_request(
        list(
          learners = learners
        )
      )


    missing_top_n_body <-
      httr2::resp_body_json(
        missing_top_n_response,
        simplifyVector = TRUE
      )


    testthat::expect_equal(
      httr2::resp_status(
        missing_top_n_response
      ),
      400
    )


    testthat::expect_match(
      missing_top_n_body$error,
      "top_n",
      fixed = TRUE
    )


    # ============================================================
    # Invalid request:
    # top_n exceeds learner count
    # ============================================================

    excessive_top_n_response <-
      perform_batch_request(
        list(
          learners = learners,
          top_n = 4
        )
      )


    excessive_top_n_body <-
      httr2::resp_body_json(
        excessive_top_n_response,
        simplifyVector = TRUE
      )


    testthat::expect_equal(
      httr2::resp_status(
        excessive_top_n_response
      ),
      400
    )


    testthat::expect_match(
      excessive_top_n_body$error,
      "cannot exceed",
      fixed = TRUE
    )


    # ============================================================
    # Invalid request:
    # fractional top_n
    # ============================================================

    fractional_top_n_response <-
      perform_batch_request(
        list(
          learners = learners,
          top_n = 1.5
        )
      )


    fractional_top_n_body <-
      httr2::resp_body_json(
        fractional_top_n_response,
        simplifyVector = TRUE
      )


    testthat::expect_equal(
      httr2::resp_status(
        fractional_top_n_response
      ),
      400
    )


    testthat::expect_match(
      fractional_top_n_body$error,
      "positive whole number",
      fixed = TRUE
    )
  }
)