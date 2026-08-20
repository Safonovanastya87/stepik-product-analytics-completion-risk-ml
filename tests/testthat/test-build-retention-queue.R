testthat::test_that(
  "retention queue ranks all learners by non-completion risk",
  {

    predictions <- data.frame(
      user_id = c(
        1001,
        1002,
        1003
      ),
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
      id_col = "user_id"
    )


    testthat::expect_equal(
      nrow(result),
      3L
    )


    testthat::expect_identical(
      names(result),
      c(
        "risk_rank",
        "user_id",
        "completion_probability",
        "completion_risk"
      )
    )


    testthat::expect_equal(
      result$user_id,
      c(
        1001,
        1002,
        1003
      )
    )


    testthat::expect_equal(
      result$completion_probability,
      c(
        0.10,
        0.40,
        0.80
      )
    )


    testthat::expect_equal(
      result$completion_risk,
      c(
        0.90,
        0.60,
        0.20
      )
    )


    testthat::expect_equal(
      result$risk_rank,
      c(
        1L,
        2L,
        3L
      )
    )
  }
)


testthat::test_that(
  "top_n limits the priority intervention queue",
  {

    predictions <- data.frame(
      user_id = c(
        1001,
        1002,
        1003
      ),
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
      top_n = 2
    )


    testthat::expect_equal(
      nrow(result),
      2L
    )


    testthat::expect_identical(
      names(result),
      c(
        "risk_rank",
        "user_id",
        "completion_probability",
        "completion_risk"
      )
    )


    testthat::expect_equal(
      result$user_id,
      c(
        1001,
        1002
      )
    )


    testthat::expect_equal(
      result$risk_rank,
      c(
        1L,
        2L
      )
    )
  }
)


testthat::test_that(
  "retention queue sorts by descending non-completion risk",
  {

    predictions <- data.frame(
      user_id = c(
        1001,
        1002,
        1003,
        1004
      ),
      completion_probability = c(
        0.30,
        0.05,
        0.20,
        0.10
      ),
      completion_risk = c(
        0.70,
        0.95,
        0.80,
        0.90
      )
    )


    result <- build_retention_queue(
      predictions = predictions,
      id_col = "user_id",
      top_n = 3
    )


    testthat::expect_equal(
      result$user_id,
      c(
        1002,
        1004,
        1003
      )
    )


    testthat::expect_true(
      all(
        diff(
          result$completion_risk
        ) <= 0
      )
    )


    testthat::expect_equal(
      result$risk_rank,
      seq_len(
        nrow(result)
      )
    )


    testthat::expect_identical(
      names(result),
      c(
        "risk_rank",
        "user_id",
        "completion_probability",
        "completion_risk"
      )
    )
  }
)


testthat::test_that(
  "top_n cannot exceed the number of scored learners",
  {

    predictions <- data.frame(
      user_id = c(
        1001,
        1002,
        1003
      ),
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


    testthat::expect_error(
      build_retention_queue(
        predictions = predictions,
        id_col = "user_id",
        top_n = 4
      ),
      "`top_n` cannot exceed the number of scored learners"
    )
  }
)