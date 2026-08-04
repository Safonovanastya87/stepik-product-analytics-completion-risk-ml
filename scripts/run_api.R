# Start the Completion Risk Prediction API

source("api/plumber.R")


plumber::pr_run(
  pr = api,
  host = "127.0.0.1",
  port = 8001
)