testthat::test_that(
  "retention queue filters and ranks learners",
  {
    predictions <- data.frame(
      user_id = c(1001, 1002, 1003),
      completion_probability = c(
        0.10,
        0.40,
        0.80
      ),
      completion_risk = c(
        0.90,
        0.60,
        0.20
      )
    )

    result <- build_retention_queue(
      predictions = predictions,
      id_col = "user_id",
      min_risk = 0.5
    )

    testthat::expect_equal(
      result$user_id,
      c(1001, 1002)
    )

    testthat::expect_equal(
      result$risk_rank,
      c(1L, 2L)
    )

    testthat::expect_true(
      all(
        result$completion_risk >= 0.5
      )
    )
  }
)


testthat::test_that(
  "top_n limits the retention queue",
  {
    predictions <- data.frame(
      user_id = c(1001, 1002, 1003),
      completion_probability = c(
        0.10,
        0.20,
        0.30
      ),
      completion_risk = c(
        0.90,
        0.80,
        0.70
      )
    )

    result <- build_retention_queue(
      predictions = predictions,
      id_col = "user_id",
      min_risk = 0,
      top_n = 1
    )

    testthat::expect_equal(
      nrow(result),
      1
    )

    testthat::expect_equal(
      result$user_id,
      1001
    )

    testthat::expect_equal(
      result$risk_rank,
      1L
    )
  }
)