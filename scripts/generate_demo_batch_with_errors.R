library(readxl)
library(writexl)


# ============================================================
# Generate demo batch with intentional validation errors
# ============================================================

input_file <- "data/demo_batch_learners.xlsx"

output_file <- "data/demo_batch_learners_with_errors.xlsx"


# ============================================================
# Read valid demo data
# ============================================================

if (!file.exists(input_file)) {

  stop(
    paste(
      "Source demo file not found:",
      input_file
    )
  )
}


demo <- readxl::read_excel(
  input_file
)


demo <- as.data.frame(
  demo,
  check.names = FALSE,
  stringsAsFactors = FALSE
)


if (nrow(demo) < 100L) {

  stop(
    "The demo file must contain at least 100 learners."
  )
}


# ============================================================
# Add intentional validation errors
# ============================================================


# ------------------------------------------------------------
# Error 1
# Row 5:
# user_id must be a positive whole number
# ------------------------------------------------------------

demo$user_id[5] <- 0


# ------------------------------------------------------------
# Error 2
# Row 12:
# active_days must be between 1 and 10
# ------------------------------------------------------------

demo$active_days[12] <- 15


# ------------------------------------------------------------
# Error 3
# Row 20:
# days_since_last_action must be between 0 and 9
# ------------------------------------------------------------

demo$days_since_last_action[20] <- 12


# ------------------------------------------------------------
# Error 4
# Row 28:
# n_passed_all must be between 0 and 198
# ------------------------------------------------------------

demo$n_passed_all[28] <- 250


# ------------------------------------------------------------
# Error 5
# Row 36:
# n_viewed_all must be non-negative
# ------------------------------------------------------------

demo$n_viewed_all[36] <- -1


# ------------------------------------------------------------
# Error 6
# Row 44:
# submission_correct_rate must be between 0 and 1
# ------------------------------------------------------------

demo$submission_correct_rate[44] <- 1.5


# ------------------------------------------------------------
# Error 7
# Row 52:
# score_per_active_day must be between 0 and 88
# ------------------------------------------------------------

demo$score_per_active_day[52] <- 90


# ------------------------------------------------------------
# Error 8
# Row 60:
# steps_per_active_day must be between 0 and 198
# ------------------------------------------------------------

demo$steps_per_active_day[60] <- 200


# ------------------------------------------------------------
# Error 9
# Row 68:
# n_passed_practical must be between 0 and 76
# ------------------------------------------------------------

demo$n_passed_practical[68] <- 80


# ------------------------------------------------------------
# Error 10
# Row 81:
# passed practical steps cannot exceed
# started practical steps
#
# Other directly related fields are kept valid.
# ------------------------------------------------------------

demo$n_started_practical[81] <- 1

demo$n_passed_practical[81] <- 2

demo$n_passed_all[81] <- max(
  as.numeric(
    demo$n_passed_all[81]
  ),
  2
)

demo$n_submissions[81] <- max(
  as.numeric(
    demo$n_submissions[81]
  ),
  2
)


# ------------------------------------------------------------
# Error 11
# Row 89:
# passed practical steps cannot exceed
# total passed steps
#
# Keep started-practical and submission values valid so the
# intended error remains isolated.
# ------------------------------------------------------------

demo$n_passed_all[89] <- 1

demo$n_started_practical[89] <- max(
  as.numeric(
    demo$n_started_practical[89]
  ),
  2
)

demo$n_passed_practical[89] <- 2

demo$n_submissions[89] <- max(
  as.numeric(
    demo$n_submissions[89]
  ),
  1
)


# ------------------------------------------------------------
# Error 12
# Row 97:
# submissions cannot be present when no practical step
# was started
#
# n_passed_practical is explicitly set to zero so that this
# row demonstrates only the started/submission inconsistency.
# ------------------------------------------------------------

demo$n_started_practical[97] <- 0

demo$n_passed_practical[97] <- 0

demo$n_submissions[97] <- 3

demo$submission_correct_rate[97] <- 0


# ============================================================
# Sanity checks for intentional errors
# ============================================================

invalid_rows <- c(
  5L,
  12L,
  20L,
  28L,
  36L,
  44L,
  52L,
  60L,
  68L,
  81L,
  89L,
  97L
)


stopifnot(

  length(invalid_rows) == 12L,

  length(unique(invalid_rows)) == 12L,


  # Row 5
  demo$user_id[5] <= 0,


  # Row 12
  demo$active_days[12] > 10,


  # Row 20
  demo$days_since_last_action[20] > 9,


  # Row 28
  demo$n_passed_all[28] > 198,


  # Row 36
  demo$n_viewed_all[36] < 0,


  # Row 44
  demo$submission_correct_rate[44] > 1,


  # Row 52
  demo$score_per_active_day[52] > 88,


  # Row 60
  demo$steps_per_active_day[60] > 198,


  # Row 68
  demo$n_passed_practical[68] > 76,


  # Row 81
  demo$n_passed_practical[81] >
    demo$n_started_practical[81],

  demo$n_passed_practical[81] <=
    demo$n_passed_all[81],

  demo$n_submissions[81] > 0,


  # Row 89
  demo$n_passed_practical[89] >
    demo$n_passed_all[89],

  demo$n_passed_practical[89] <=
    demo$n_started_practical[89],

  demo$n_submissions[89] > 0,


  # Row 97
  demo$n_submissions[97] > 0,

  demo$n_started_practical[97] == 0,

  demo$n_passed_practical[97] == 0
)


# ============================================================
# Save second demo file
# ============================================================

writexl::write_xlsx(
  demo,
  output_file
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
  "Intentional invalid rows:",
  length(invalid_rows),
  "\n\n"
)


cat(
  "Invalid row summary:\n"
)


cat(
  "Row 5  - invalid user_id\n"
)

cat(
  "Row 12 - active_days > 10\n"
)

cat(
  "Row 20 - days_since_last_action > 9\n"
)

cat(
  "Row 28 - n_passed_all > 198\n"
)

cat(
  "Row 36 - negative n_viewed_all\n"
)

cat(
  "Row 44 - submission_correct_rate > 1\n"
)

cat(
  "Row 52 - score_per_active_day > 88\n"
)

cat(
  "Row 60 - steps_per_active_day > 198\n"
)

cat(
  "Row 68 - n_passed_practical > 76\n"
)

cat(
  "Row 81 - n_passed_practical > n_started_practical\n"
)

cat(
  "Row 89 - n_passed_practical > n_passed_all\n"
)

cat(
  "Row 97 - submissions present without practical start\n"
)


cat(
  "\nExpected batch validation result:",
  "\n100 uploaded",
  "\n88 scored",
  "\n12 rejected\n"
)