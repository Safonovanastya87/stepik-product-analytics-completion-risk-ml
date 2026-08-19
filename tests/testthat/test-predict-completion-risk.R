testthat::test_that(
  "prediction returns valid completion probabilities and risks",
  {

    result <- predict_completion_risk(
      data = valid_test_data,
      loaded_model = loaded_model
    )


    # ============================================================
    # Row count
    # ============================================================

    testthat::expect_equal(
      nrow(result),
      nrow(valid_test_data)
    )


    # ============================================================
    # Output structure
    # ============================================================

    expected_columns <- c(
      names(valid_test_data),
      "completion_probability",
      "completion_risk"
    )


    testthat::expect_setequal(
      names(result),
      expected_columns
    )


    testthat::expect_false(
      "classification_threshold" %in%
        names(result)
    )


    testthat::expect_false(
      "predicted_completion_status" %in%
        names(result)
    )


    # ============================================================
    # Probability types
    # ============================================================

    testthat::expect_true(
      is.numeric(
        result$completion_probability
      )
    )


    testthat::expect_true(
      is.numeric(
        result$completion_risk
      )
    )


    # ============================================================
    # Probability ranges
    # ============================================================

    testthat::expect_true(
      all(
        is.finite(
          result$completion_probability
        )
      )
    )


    testthat::expect_true(
      all(
        is.finite(
          result$completion_risk
        )
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


    # ============================================================
    # Probability relationship
    # ============================================================

    testthat::expect_equal(
      result$completion_risk,
      1 - result$completion_probability,
      tolerance = 1e-8
    )


    testthat::expect_equal(
      result$completion_probability +
        result$completion_risk,
      rep(
        1,
        nrow(result)
      ),
      tolerance = 1e-8
    )
  }
)


testthat::test_that(
  "prediction rejects missing required features",
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