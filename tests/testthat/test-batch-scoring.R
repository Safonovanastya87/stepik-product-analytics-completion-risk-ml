testthat::test_that(
  "batch scoring creates valid prediction and priority queue output files",
  {

    # ============================================================
    # Temporary file paths
    # ============================================================

    input_path <- tempfile(
      fileext = ".xlsx"
    )


    predictions_output_path <- tempfile(
      fileext = ".xlsx"
    )


    queue_output_path <- tempfile(
      fileext = ".xlsx"
    )


    # ============================================================
    # Prepare input XLSX
    # ============================================================

    writexl::write_xlsx(
      valid_test_data,
      input_path
    )


    top_n <- min(
      2L,
      nrow(valid_test_data)
    )


    # ============================================================
    # Run batch scoring
    # ============================================================

    result <- run_batch_scoring(
      input_path = input_path,
      predictions_output_path =
        predictions_output_path,
      queue_output_path =
        queue_output_path,
      artifact_path = file.path(
        project_root,
        "artifacts",
        "completion_risk_artifact.rds"
      ),
      id_col = "user_id",
      top_n = top_n
    )


    # ============================================================
    # Output files exist
    # ============================================================

    testthat::expect_true(
      file.exists(
        predictions_output_path
      )
    )


    testthat::expect_true(
      file.exists(
        queue_output_path
      )
    )


    # ============================================================
    # Returned object structure
    # ============================================================

    testthat::expect_s3_class(
      result$predictions,
      "data.frame"
    )


    testthat::expect_s3_class(
      result$retention_queue,
      "data.frame"
    )


    testthat::expect_equal(
      result$predictions_output_path,
      predictions_output_path
    )


    testthat::expect_equal(
      result$queue_output_path,
      queue_output_path
    )


    # ============================================================
    # Prediction row count
    # ============================================================

    testthat::expect_equal(
      nrow(result$predictions),
      nrow(valid_test_data)
    )


    # ============================================================
    # Prediction output contract
    # ============================================================

    expected_prediction_columns <- c(
      names(valid_test_data),
      "completion_probability",
      "completion_risk"
    )


    testthat::expect_identical(
      names(result$predictions),
      expected_prediction_columns
    )


    testthat::expect_false(
      "classification_threshold" %in%
        names(result$predictions)
    )


    testthat::expect_false(
      "predicted_completion_status" %in%
        names(result$predictions)
    )


    # ============================================================
    # Prediction probability values
    # ============================================================

    testthat::expect_true(
      is.numeric(
        result$predictions$
          completion_probability
      )
    )


    testthat::expect_true(
      is.numeric(
        result$predictions$
          completion_risk
      )
    )


    testthat::expect_true(
      all(
        is.finite(
          result$predictions$
            completion_probability
        )
      )
    )


    testthat::expect_true(
      all(
        is.finite(
          result$predictions$
            completion_risk
        )
      )
    )


    testthat::expect_true(
      all(
        result$predictions$
          completion_probability >= 0 &
          result$predictions$
            completion_probability <= 1
      )
    )


    testthat::expect_true(
      all(
        result$predictions$
          completion_risk >= 0 &
          result$predictions$
            completion_risk <= 1
      )
    )


    testthat::expect_equal(
      result$predictions$
        completion_risk,
      1 -
        result$predictions$
          completion_probability,
      tolerance = 1e-8
    )


    # ============================================================
    # Priority queue row count
    # ============================================================

    testthat::expect_equal(
      nrow(result$retention_queue),
      top_n
    )


    # ============================================================
    # Priority queue output contract
    # ============================================================

    expected_queue_columns <- c(
      "risk_rank",
      "user_id",
      "completion_probability",
      "completion_risk"
    )


    testthat::expect_identical(
      names(result$retention_queue),
      expected_queue_columns
    )


    testthat::expect_false(
      "classification_threshold" %in%
        names(result$retention_queue)
    )


    testthat::expect_false(
      "predicted_completion_status" %in%
        names(result$retention_queue)
    )


    # ============================================================
    # Priority ranking
    # ============================================================

    testthat::expect_equal(
      result$retention_queue$
        risk_rank,
      seq_len(
        nrow(result$retention_queue)
      )
    )


    testthat::expect_true(
      all(
        diff(
          result$retention_queue$
            completion_risk
        ) <= 0
      )
    )


    # ============================================================
    # Queue contains actual Top-N learners
    # ============================================================

    expected_order <- order(
      -result$predictions$
        completion_risk,
      seq_len(
        nrow(result$predictions)
      )
    )


    expected_top_ids <-
      result$predictions$user_id[
        head(
          expected_order,
          top_n
        )
      ]


    testthat::expect_equal(
      result$retention_queue$user_id,
      expected_top_ids
    )


    # ============================================================
    # Queue probabilities
    # ============================================================

    testthat::expect_true(
      all(
        result$retention_queue$
          completion_probability >= 0 &
          result$retention_queue$
            completion_probability <= 1
      )
    )


    testthat::expect_true(
      all(
        result$retention_queue$
          completion_risk >= 0 &
          result$retention_queue$
            completion_risk <= 1
      )
    )


    testthat::expect_equal(
      result$retention_queue$
        completion_risk,
      1 -
        result$retention_queue$
          completion_probability,
      tolerance = 1e-8
    )


    # ============================================================
    # Read saved XLSX files
    # ============================================================

    saved_predictions <- readxl::read_excel(
      predictions_output_path
    )

    saved_predictions <- as.data.frame(
      saved_predictions,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )


    saved_queue <- readxl::read_excel(
      queue_output_path
    )

    saved_queue <- as.data.frame(
      saved_queue,
      check.names = FALSE,
      stringsAsFactors = FALSE
    )


    # ============================================================
    # Saved prediction XLSX contract
    # ============================================================

    testthat::expect_identical(
      names(saved_predictions),
      expected_prediction_columns
    )


    testthat::expect_equal(
      nrow(saved_predictions),
      nrow(result$predictions)
    )


    testthat::expect_false(
      "classification_threshold" %in%
        names(saved_predictions)
    )


    testthat::expect_false(
      "predicted_completion_status" %in%
        names(saved_predictions)
    )


    testthat::expect_true(
      all(
        saved_predictions$
          completion_probability >= 0 &
          saved_predictions$
            completion_probability <= 1
      )
    )


    testthat::expect_true(
      all(
        saved_predictions$
          completion_risk >= 0 &
          saved_predictions$
            completion_risk <= 1
      )
    )


    testthat::expect_equal(
      saved_predictions$
        completion_risk,
      1 -
        saved_predictions$
          completion_probability,
      tolerance = 1e-8
    )


    # ============================================================
    # Saved queue XLSX contract
    # ============================================================

    testthat::expect_identical(
      names(saved_queue),
      expected_queue_columns
    )


    testthat::expect_equal(
      nrow(saved_queue),
      nrow(result$retention_queue)
    )


    testthat::expect_equal(
      saved_queue$risk_rank,
      seq_len(
        nrow(saved_queue)
      )
    )


    testthat::expect_true(
      all(
        diff(
          saved_queue$
            completion_risk
        ) <= 0
      )
    )


    testthat::expect_true(
      all(
        saved_queue$
          completion_probability >= 0 &
          saved_queue$
            completion_probability <= 1
      )
    )


    testthat::expect_true(
      all(
        saved_queue$
          completion_risk >= 0 &
          saved_queue$
            completion_risk <= 1
      )
    )


    testthat::expect_equal(
      saved_queue$
        completion_risk,
      1 -
        saved_queue$
          completion_probability,
      tolerance = 1e-8
    )
  }
)


testthat::test_that(
  "batch scoring prioritizes all learners when top_n is NULL",
  {

    # ============================================================
    # Temporary file paths
    # ============================================================

    input_path <- tempfile(
      fileext = ".xlsx"
    )


    predictions_output_path <- tempfile(
      fileext = ".xlsx"
    )


    queue_output_path <- tempfile(
      fileext = ".xlsx"
    )


    # ============================================================
    # Prepare input XLSX
    # ============================================================

    writexl::write_xlsx(
      valid_test_data,
      input_path
    )


    # ============================================================
    # Run without explicit Top N
    # ============================================================

    result <- run_batch_scoring(
      input_path = input_path,
      predictions_output_path =
        predictions_output_path,
      queue_output_path =
        queue_output_path,
      artifact_path = file.path(
        project_root,
        "artifacts",
        "completion_risk_artifact.rds"
      ),
      id_col = "user_id"
    )


    # ============================================================
    # All scored learners must be prioritized
    # ============================================================

    testthat::expect_equal(
      nrow(result$retention_queue),
      nrow(result$predictions)
    )


    testthat::expect_equal(
      result$retention_queue$
        risk_rank,
      seq_len(
        nrow(result$retention_queue)
      )
    )


    # ============================================================
    # Queue must still be sorted by descending risk
    # ============================================================

    testthat::expect_true(
      all(
        diff(
          result$retention_queue$
            completion_risk
        ) <= 0
      )
    )


    # ============================================================
    # Strict queue contract
    # ============================================================

    testthat::expect_identical(
      names(result$retention_queue),
      c(
        "risk_rank",
        "user_id",
        "completion_probability",
        "completion_risk"
      )
    )


    # ============================================================
    # All learner IDs must appear exactly once
    # ============================================================

    testthat::expect_setequal(
      result$retention_queue$user_id,
      result$predictions$user_id
    )


    testthat::expect_equal(
      length(
        unique(
          result$retention_queue$user_id
        )
      ),
      nrow(result$retention_queue)
    )
  }
)