testthat::test_that(
  "valid prediction input is accepted",
  {
    result <- validate_prediction_input(
      data = valid_test_data,
      feature_cols = feature_cols
    )

    testthat::expect_s3_class(
      result,
      "data.frame"
    )

    testthat::expect_equal(
      nrow(result),
      1
    )

    testthat::expect_equal(
      names(result),
      feature_cols
    )
  }
)


testthat::test_that(
  "missing model features are rejected",
  {
    invalid_data <- valid_test_data

    invalid_data$active_days <- NULL

    testthat::expect_error(
      validate_prediction_input(
        data = invalid_data,
        feature_cols = feature_cols
      ),
      "Missing required features"
    )
  }
)


testthat::test_that(
  "non-numeric features are rejected",
  {
    invalid_data <- valid_test_data

    invalid_data$active_days <- "five"

    testthat::expect_error(
      validate_prediction_input(
        data = invalid_data,
        feature_cols = feature_cols
      ),
      "must be numeric"
    )
  }
)