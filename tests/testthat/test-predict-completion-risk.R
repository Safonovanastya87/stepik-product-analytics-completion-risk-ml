testthat::test_that(
  "prediction returns valid probabilities",
  {
    result <- predict_completion_risk(
      data = valid_test_data,
      loaded_model = loaded_model
    )

    testthat::expect_equal(
      nrow(result),
      nrow(valid_test_data)
    )

    testthat::expect_true(
      all(
        c(
          "completion_probability",
          "completion_risk"
        ) %in% names(result)
      )
    )

    testthat::expect_true(
      all(
        result$completion_probability >= 0 &
          result$completion_probability <= 1
      )
    )

    testthat::expect_true(
      all(
        result$completion_risk >= 0 &
          result$completion_risk <= 1
      )
    )

    testthat::expect_equal(
      result$completion_probability +
        result$completion_risk,
      rep(1, nrow(result)),
      tolerance = 1e-7
    )
  }
)


testthat::test_that(
  "prediction rejects missing features",
  {
    invalid_data <- valid_test_data

    invalid_data$active_days <- NULL

    testthat::expect_error(
      predict_completion_risk(
        data = invalid_data,
        loaded_model = loaded_model
      ),
      "Missing required features"
    )
  }
)