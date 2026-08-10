# ============================================================
# Generate demo batch with intentional validation errors
# ============================================================

input_file <- "data/demo_batch_learners.csv"

output_file <- "data/demo_batch_learners_with_errors.csv"


# ------------------------------------------------------------
# Read valid demo data
# ------------------------------------------------------------

if (!file.exists(input_file)) {
  stop(
    paste(
      "Source demo file not found:",
      input_file
    )
  )
}


demo <- read.csv(
  input_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


if (nrow(demo) < 81) {
  stop(
    "The demo file must contain at least 81 learners."
  )
}


# ============================================================
# Add 3 intentional errors
# ============================================================


# ------------------------------------------------------------
# Error 1
# Row 12:
# active_days must be between 1 and 10
# ------------------------------------------------------------

demo$active_days[12] <- 15


# ------------------------------------------------------------
# Error 2
# Row 37:
# submission_correct_rate must be between 0 and 1
# ------------------------------------------------------------

demo$submission_correct_rate[37] <- 1.5


# ------------------------------------------------------------
# Error 3
# Row 81:
# passed practical steps cannot exceed started practical steps
#
# We also make sure the other related values remain valid,
# so this row demonstrates one clear cross-field error.
# ------------------------------------------------------------

demo$n_started_practical[81] <- 1

demo$n_passed_practical[81] <- 2

demo$n_passed_all[81] <- max(
  as.numeric(demo$n_passed_all[81]),
  2
)

demo$n_submissions[81] <- max(
  as.numeric(demo$n_submissions[81]),
  1
)


# ============================================================
# Save second demo file
# ============================================================

write.csv(
  demo,
  output_file,
  row.names = FALSE,
  na = ""
)


# ============================================================
# Console summary
# ============================================================

cat(
  "\nCreated:",
  output_file,
  "\n"
)

cat(
  "Rows:",
  nrow(demo),
  "\n"
)

cat(
  "Intentional invalid rows: 3\n\n"
)


cat("Row 12:\n")
print(
  demo[
    12,
    c(
      "user_id",
      "active_days"
    ),
    drop = FALSE
  ]
)


cat("\nRow 37:\n")
print(
  demo[
    37,
    c(
      "user_id",
      "submission_correct_rate"
    ),
    drop = FALSE
  ]
)


cat("\nRow 81:\n")
print(
  demo[
    81,
    c(
      "user_id",
      "n_passed_all",
      "n_started_practical",
      "n_passed_practical",
      "n_submissions"
    ),
    drop = FALSE
  ]
)


cat(
  "\nExpected batch validation result:",
  "\n100 uploaded",
  "\n97 scored",
  "\n3 rejected\n"
)