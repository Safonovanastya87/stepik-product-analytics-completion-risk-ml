set.seed(20260807)


# ============================================================
# Configuration
# ============================================================

n_per_profile <- 20L

profiles <- c(
  "low_activation",
  "early_dropout",
  "moderate",
  "active",
  "high_performer"
)


# ============================================================
# Helper
# ============================================================

generate_profile <- function(
  profile,
  n,
  start_id
) {
  user_id <- seq.int(
    from = start_id,
    length.out = n
  )

  if (profile == "low_activation") {
    active_days <- sample(1:3, n, replace = TRUE)
    n_passed_all <- sample(0:4, n, replace = TRUE)
    n_viewed_all <- n_passed_all + sample(2:15, n, replace = TRUE)
    n_started_practical <- sample(0:2, n, replace = TRUE)

  } else if (profile == "early_dropout") {
    active_days <- sample(2:5, n, replace = TRUE)
    n_passed_all <- sample(2:12, n, replace = TRUE)
    n_viewed_all <- n_passed_all + sample(5:20, n, replace = TRUE)
    n_started_practical <- sample(1:6, n, replace = TRUE)

  } else if (profile == "moderate") {
    active_days <- sample(4:7, n, replace = TRUE)
    n_passed_all <- sample(10:35, n, replace = TRUE)
    n_viewed_all <- n_passed_all + sample(10:30, n, replace = TRUE)
    n_started_practical <- sample(4:18, n, replace = TRUE)

  } else if (profile == "active") {
    active_days <- sample(6:9, n, replace = TRUE)
    n_passed_all <- sample(30:75, n, replace = TRUE)
    n_viewed_all <- n_passed_all + sample(15:40, n, replace = TRUE)
    n_started_practical <- sample(15:35, n, replace = TRUE)

  } else {
    active_days <- sample(8:10, n, replace = TRUE)
    n_passed_all <- sample(70:150, n, replace = TRUE)
    n_viewed_all <- n_passed_all + sample(20:50, n, replace = TRUE)
    n_started_practical <- sample(30:60, n, replace = TRUE)
  }


  # ----------------------------------------------------------
  # Practical progress
  # ----------------------------------------------------------

  n_passed_practical <- vapply(
    seq_len(n),
    function(i) {
      max_allowed <- min(
        n_started_practical[i],
        n_passed_all[i],
        76L
      )

      if (max_allowed == 0L) {
        return(0L)
      }

      sample(
        0:max_allowed,
        1
      )
    },
    integer(1)
  )


  # ----------------------------------------------------------
  # Submission activity
  # ----------------------------------------------------------

  n_submissions <- vapply(
    seq_len(n),
    function(i) {
      if (n_started_practical[i] == 0L) {
        return(0L)
      }

      minimum <- if (
        n_passed_practical[i] > 0L
      ) {
        1L
      } else {
        0L
      }

      maximum <- max(
        minimum,
        n_started_practical[i] * 3L
      )

      sample(
        minimum:maximum,
        1
      )
    },
    integer(1)
  )


  submission_correct_rate <- vapply(
    seq_len(n),
    function(i) {
      if (n_submissions[i] == 0L) {
        return(0)
      }

      round(
        runif(
          1,
          min = 0.10,
          max = 0.95
        ),
        2
      )
    },
    numeric(1)
  )


  # ----------------------------------------------------------
  # Recency
  # ----------------------------------------------------------

  days_since_last_action <- if (
    profile %in% c(
      "low_activation",
      "early_dropout"
    )
  ) {
    sample(
      4:9,
      n,
      replace = TRUE
    )
  } else if (profile == "moderate") {
    sample(
      2:6,
      n,
      replace = TRUE
    )
  } else {
    sample(
      0:3,
      n,
      replace = TRUE
    )
  }


  # ----------------------------------------------------------
  # Derived / intensity features
  # ----------------------------------------------------------

  steps_per_active_day <- round(
    n_passed_all / active_days,
    2
  )

  score_per_active_day <- round(
    pmin(
      88,
      (
        n_passed_practical *
          submission_correct_rate
      ) / active_days
    ),
    2
  )


  data.frame(
    user_id = user_id,
    n_passed_all = n_passed_all,
    n_viewed_all = n_viewed_all,
    n_started_practical = n_started_practical,
    n_passed_practical = n_passed_practical,
    n_submissions = n_submissions,
    submission_correct_rate = submission_correct_rate,
    active_days = active_days,
    days_since_last_action = days_since_last_action,
    score_per_active_day = score_per_active_day,
    steps_per_active_day = steps_per_active_day,
    stringsAsFactors = FALSE
  )
}


# ============================================================
# Generate 100 synthetic learners
# ============================================================

demo_data <- do.call(
  rbind,
  lapply(
    seq_along(profiles),
    function(i) {
      generate_profile(
        profile = profiles[i],
        n = n_per_profile,
        start_id = 10001L +
          ((i - 1L) * n_per_profile)
      )
    }
  )
)

rownames(demo_data) <- NULL


# ============================================================
# Save
# ============================================================

output_path <- file.path(
  "data",
  "demo_batch_learners.csv"
)

write.csv(
  demo_data,
  output_path,
  row.names = FALSE
)

cat(
  "Demo batch dataset created:\n",
  output_path,
  "\nLearners:",
  nrow(demo_data),
  "\n"
)