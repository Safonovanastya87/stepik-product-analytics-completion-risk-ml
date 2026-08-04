testthat::test_that(
  "batch scoring creates prediction output files",
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
      id_col = "user_id",
      min_risk = 0.5
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


    testthat::expect_s3_class(
      object = result$retention_queue,
      class = "data.frame"
    )
  }
)