testthat::test_that(
  "batch scoring creates prediction and priority queue output files",
  {

    input_path <- tempfile(
      fileext = ".csv"
    )


    predictions_output_path <- tempfile(
      fileext = ".csv"
    )


    queue_output_path <- tempfile(
      fileext = ".csv"
    )


    write.csv(
      valid_test_data,
      input_path,
      row.names = FALSE
    )


    top_n <- min(
      2L,
      nrow(valid_test_data)
    )


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


    testthat::expect_equal(
      nrow(result$predictions),
      nrow(valid_test_data)
    )


    testthat::expect_equal(
      nrow(result$retention_queue),
      top_n
    )


    testthat::expect_true(
      all(
        c(
          "completion_probability",
          "completion_risk"
        ) %in% names(
          result$predictions
        )
      )
    )


    testthat::expect_true(
      all(
        c(
          "risk_rank",
          "user_id",
          "completion_risk",
          "completion_probability"
        ) %in% names(
          result$retention_queue
        )
      )
    )


    testthat::expect_equal(
      result$retention_queue$risk_rank,
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


    saved_predictions <- read.csv(
      predictions_output_path,
      stringsAsFactors = FALSE
    )


    saved_queue <- read.csv(
      queue_output_path,
      stringsAsFactors = FALSE
    )


    testthat::expect_equal(
      nrow(saved_predictions),
      nrow(result$predictions)
    )


    testthat::expect_equal(
      nrow(saved_queue),
      nrow(result$retention_queue)
    )


    testthat::expect_s3_class(
      object = result$retention_queue,
      class = "data.frame"
    )
  }
)


testthat::test_that(
  "batch scoring prioritizes all learners when top_n is NULL",
  {

    input_path <- tempfile(
      fileext = ".csv"
    )


    predictions_output_path <- tempfile(
      fileext = ".csv"
    )


    queue_output_path <- tempfile(
      fileext = ".csv"
    )


    write.csv(
      valid_test_data,
      input_path,
      row.names = FALSE
    )


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


    testthat::expect_equal(
      nrow(result$retention_queue),
      nrow(result$predictions)
    )


    testthat::expect_equal(
      result$retention_queue$risk_rank,
      seq_len(
        nrow(result$retention_queue)
      )
    )
  }
)