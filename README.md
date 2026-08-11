# Stepik EdTech Analytics and Learner Non-Completion Risk

![R](https://img.shields.io/badge/R-4.6.1-blue)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange)
![Machine Learning](https://img.shields.io/badge/ML-XGBoost-green)
![Shiny](https://img.shields.io/badge/UI-Shiny-blue)
![Plumber](https://img.shields.io/badge/API-Plumber-lightgrey)
![Product Analytics](https://img.shields.io/badge/Product%20Analytics-Retention%20%7C%20Segmentation-purple)
![Testing](https://img.shields.io/badge/Testing-testthat-blueviolet)
![Status](https://img.shields.io/badge/Status-Portfolio%20Project-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Project Overview

This project is an end-to-end EdTech analytics and machine learning case study based on learner activity data from the online learning platform **Stepik**.

It combines:

- product analytics;
- learning journey analysis;
- behavioral segmentation;
- completion-risk modeling;
- reusable model inference;
- a Plumber prediction API;
- a Shiny decision-support interface;
- batch prioritization for retention teams;
- automated validation and testing.

The project analyzes learner behavior in the course **Interactive Data Analysis in R** and addresses the central business question:

> Why do learners fail to complete the course, and how early can at-risk learners be identified and prioritized for retention support?

The final system moves beyond retrospective analysis by turning the trained model into a reusable prediction service for both single learners and batch CSV scoring.

---

## Business Problem

Online learning platforms often experience substantial learner drop-off before course completion.

The project investigates:

- where learners disengage during the course journey;
- which course steps create the strongest friction;
- how engagement patterns differ across learners;
- which learners are most likely to complete the course;
- how early non-completion risk can be estimated;
- how limited retention capacity can be allocated efficiently.

The product goal is not to make an automatic intervention decision. Instead, the system provides **decision support** by estimating non-completion probability and ranking learners by risk.

---

## Dataset

The project uses anonymized learner activity data from the Stepik platform.

Two public datasets are analyzed:

- **Event Data** — content views, discoveries, practical starts, and passed assignments;
- **Submission Data** — practical assignment attempts and submission outcomes.

Together, these datasets allow reconstruction of learner journeys, engagement patterns, practical activity, and completion trajectories.

---

## Project Workflow

The project consists of four connected analytical and engineering layers:

```text
Product analytics
      ↓
Behavioral segmentation
      ↓
Completion-risk modeling
      ↓
Reusable prediction API and retention-support application
```

---

## Part 1 — Product Analytics and Activation Gap Analysis

The first stage focuses on understanding learner behavior throughout the course.

The analysis includes:

- funnel analysis;
- learning journey reconstruction;
- step-level engagement analysis;
- practical assignment analysis;
- learner-level behavioral profiling.

### Key Finding

The largest learner drop-off occurs before meaningful practical engagement.

Many learners consume content passively but never transition into practical assignments. This gap between content consumption and active learning is defined as the **Activation Gap**.

---

## Part 2 — Behavioral Segmentation

The second stage uses K-Means clustering to identify learner archetypes based on engagement and learning behavior.

| Segment | Description |
|---|---|
| Passive Users | Low engagement and minimal practical activity |
| Steady Learners | Consistent participation and moderate progress |
| Burst Learners | High-intensity engagement and strong productivity |

### Key Finding

Learners exhibit distinct behavioral patterns, and completion outcomes differ substantially across segments.

---

## Part 3 — Completion Risk Modeling

The modeling stage estimates the probability of course completion using behavioral signals observed during the **first 10 course days**.

Models evaluated:

- Random Forest;
- XGBoost.

The final prediction target is:

```text
P(Completed)
```

Operational non-completion risk is derived as:

```text
Completion Risk = 1 - P(Completed)
```

The final implementation uses an XGBoost model selected based on predictive performance and the practical balance between recall, false-positive rate, and model complexity.

### Model Validation

The modeling workflow includes:

- class imbalance handling;
- hyperparameter evaluation;
- PR-AUC-based model comparison;
- F2-score and false-positive-rate analysis;
- feature importance analysis;
- dominant-feature ablation;
- engagement-only robustness checks;
- calibration diagnostics;
- final holdout evaluation.

### Classification Threshold vs. Intervention Prioritization

The model produces a **continuous completion probability**.

A classification threshold of:

```text
P(Completed) = 0.116
```

was selected during validation using the F2 score. This threshold is retained for technical binary classification such as:

```text
Predicted Completed
Predicted Not Completed
```

However, the classification threshold is **not used as a business intervention threshold**.

The retention workflow intentionally separates model classification from operational prioritization:

```text
Model classification:
P(Completed) + classification threshold
            ↓
Completed / Not Completed

Retention prioritization:
P(Not Completed)
      ↓
sort from highest to lowest risk
      ↓
Top N learners according to available intervention capacity
```

This avoids introducing an arbitrary "high-risk" cutoff into the product workflow.

---

## Part 4 — Prediction and Retention Pipeline

The trained model is exported from the modeling notebook as a reusable artifact:

```text
artifacts/completion_risk_artifact.rds
```

The artifact contains more than the trained booster:

```text
completion_risk_artifact.rds
├── model_raw
├── model_metadata
├── inference_settings
└── results
```

It stores:

- the serialized XGBoost model;
- model metadata;
- the required feature list;
- feature order;
- inference settings;
- model evaluation results.

This allows predictions to be generated without rerunning the training notebook.

### Inference Workflow

```text
New learner data
      ↓
Input validation
      ↓
XGBoost prediction
      ↓
Completion probability
      ↓
Non-completion probability
      ↓
Capacity-based priority queue
```

---

## Required Prediction Features

The model expects the following first-10-day learner features:

```text
n_passed_all
n_viewed_all
n_started_practical
n_passed_practical
n_submissions
submission_correct_rate
active_days
days_since_last_action
score_per_active_day
steps_per_active_day
```

Each prediction row also includes:

```text
user_id
```

The inference layer validates both data types and cross-field consistency before scoring.

Examples of validation rules include:

- `user_id` must be a positive whole number;
- `active_days` must be between 1 and 10;
- `days_since_last_action` must be between 0 and 9;
- `submission_correct_rate` must be between 0 and 1;
- passed practical steps cannot exceed started practical steps;
- practical passes require submissions;
- submissions require started practical steps.

---

## Prediction Output

For every learner, the model returns continuous probability estimates:

```text
completion_probability
completion_risk
```

Example:

```text
completion_probability = 0.28
completion_risk        = 0.72
```

This represents a 28% estimated probability of course completion and a 72% estimated probability of non-completion.

Technical prediction output can also include:

```text
classification_threshold
predicted_completion_status
```

These fields support model-level classification and diagnostics but are not used to define intervention priority in the Shiny application.

---

## Capacity-Based Retention Queue

The retention queue no longer filters learners by a fixed risk threshold.

Instead, it:

1. scores all valid learners;
2. sorts learners from highest to lowest `completion_risk`;
3. assigns `risk_rank`;
4. returns the first `Top N` learners according to available intervention capacity.

Example:

| risk_rank | user_id | completion_probability | completion_risk |
|---:|---:|---:|---:|
| 1 | 1001 | 0.06 | 0.94 |
| 2 | 1002 | 0.24 | 0.76 |
| 3 | 1003 | 0.39 | 0.61 |

The system therefore answers the operational question:

> Which N learners should be reviewed first if the retention team can support only N interventions?

It does **not** automatically label a probability as "high risk" or "low risk" without an independently justified business threshold.

---

## Shiny Application

The project includes a Shiny decision-support interface with two workflows.

### Single Learner

The **Single Learner** tab accepts one learner profile and returns:

```text
Estimated non-completion probability
```

The interface deliberately displays the continuous probability rather than a categorical high/low-risk label.

![Single Learner prediction](docs/images/shiny_single.png)

### Batch CSV

The **Batch CSV** tab supports:

- CSV upload;
- preview of the expected 11 input columns;
- row-level validation;
- scoring of valid learners;
- separate reporting of rejected rows;
- configurable `Learners to prioritize`;
- capacity-based Top N prioritization;
- downloadable queue;
- downloadable full scoring results;
- downloadable validation errors.

If a CSV contains invalid rows, the application can still score the valid rows and reports rejected rows separately.

Example:

```text
100 uploaded
97 scored
3 rejected
18 prioritized
```

The priority queue and rejected-row tables use internal scrolling so large batches do not expand the entire page.

![Batch learner prioritization](docs/images/shiny_batch.png)

---

## Plumber API

The model is exposed through a Plumber API.

### `GET /health`

Returns model and inference metadata such as:

```text
status
model_loaded
model_class
required_feature_count
observation_window_days
```

### `POST /predict`

Scores exactly one learner.

Conceptual response:

```json
{
  "user_id": 1001,
  "completion_probability": 0.28,
  "completion_risk": 0.72,
  "classification_threshold": 0.116,
  "predicted_completion_status": "..."
}
```

### `POST /predict-batch`

Scores multiple learners and builds a capacity-based priority queue.

Request:

```json
{
  "learners": [
    {
      "user_id": 1001,
      "n_passed_all": 3,
      "n_viewed_all": 15,
      "n_started_practical": 2,
      "n_passed_practical": 1,
      "n_submissions": 4,
      "submission_correct_rate": 0.25,
      "active_days": 3,
      "days_since_last_action": 6,
      "score_per_active_day": 1,
      "steps_per_active_day": 5
    }
  ],
  "top_n": 1
}
```

Conceptual response structure:

```json
{
  "learner_count": 1,
  "queue_count": 1,
  "top_n": 1,
  "predictions": [],
  "retention_queue": []
}
```

`min_risk` is intentionally absent from the batch API contract.

---

## Production-Style R Components

Reusable inference logic is separated from exploratory notebooks.

### `R/load_artifact.R`

Loads and validates the saved model artifact and restores the trained XGBoost booster.

### `R/validate_prediction_input.R`

Validates feature structure, ranges, numeric types, and cross-field consistency before inference.

### `R/predict_completion_risk.R`

Runs the trained model and adds:

```text
completion_probability
completion_risk
classification_threshold
predicted_completion_status
```

### `R/build_retention_queue.R`

Sorts scored learners by descending non-completion risk, assigns `risk_rank`, and returns the requested Top N learners.

### `R/batch_scoring.R`

Provides file-based batch scoring:

```text
CSV
 ↓
prediction
 ↓
priority queue
 ↓
prediction CSV + queue CSV
```

---

## Example R Usage

```r
source("R/load_artifact.R")
source("R/validate_prediction_input.R")
source("R/predict_completion_risk.R")
source("R/build_retention_queue.R")

loaded_model <- load_completion_risk_artifact()

new_learners <- read.csv(
  "path/to/new_learner_features.csv"
)

predictions <- predict_completion_risk(
  data = new_learners,
  loaded_model = loaded_model
)

retention_queue <- build_retention_queue(
  predictions = predictions,
  id_col = "user_id",
  top_n = 100
)
```

---

## Demo Batch Data

The repository contains scripts for generating reproducible demonstration data.

```text
scripts/generate_demo_batch.R
scripts/generate_demo_batch_with_errors.R
```

The first script produces a valid batch dataset.

The second produces a controlled error fixture containing invalid rows so the Shiny validation and rejected-row workflow can be demonstrated.

---

## Automated Testing

The project uses `testthat` for unit and integration testing.

The automated suite covers:

- prediction input validation;
- range and cross-field validation;
- model prediction behavior;
- retention-queue ranking;
- Top N capacity behavior;
- batch scoring;
- API integration;
- batch API integration.

The updated tests explicitly verify that the priority queue:

- sorts by descending non-completion risk;
- assigns sequential `risk_rank`;
- respects `top_n`;
- rejects impossible capacity values.

Run the full test suite with:

```r
testthat::test_dir(
  "tests/testthat",
  reporter = "summary"
)
```

The expected result is a suite with no failed tests.

---

## Running the Project Locally

The project uses `renv` for reproducible package management.

### Restore dependencies

```r
install.packages("renv")
renv::restore()
```

### Start the Plumber API

From the project root:

```powershell
$Rscript = "D:\R-4.6.1\bin\x64\Rscript.exe"

& $Rscript -e "source('renv/activate.R'); source('scripts/run_api.R')"
```

The API runs locally on:

```text
http://127.0.0.1:8001
```

### Start the Shiny application

In a second terminal:

```powershell
$Rscript = "D:\R-4.6.1\bin\x64\Rscript.exe"

& $Rscript -e "source('renv/activate.R'); shiny::runApp('shiny', host = '127.0.0.1', port = 3838, launch.browser = TRUE)"
```

The Shiny application runs locally on:

```text
http://127.0.0.1:3838
```

---

## Key Findings

- The largest learner drop-off occurs before practical engagement begins.
- Practical activation is one of the strongest indicators of eventual course completion.
- Learners can be grouped into distinct behavioral segments with different completion outcomes.
- Behavior during the first 10 course days contains meaningful information for early risk prediction.
- The progress-aware XGBoost approach achieves the strongest overall predictive performance.
- XGB Baseline is retained as the final operational model because further tuning provides only a marginal PR-AUC improvement while producing a slightly less favorable F2–FPR trade-off.
- Engagement-only features remain informative after direct progress- and submission-related variables are removed.
- Product analytics, behavioral segmentation, and predictive modeling can be combined into a unified learner-retention framework.
- The trained model can be reused independently of the original modeling notebook.

---

## Business Impact

The project demonstrates how educational-platform data can support proactive and capacity-aware learner-retention strategies.

Potential applications include:

- identifying learners with elevated non-completion probability;
- ranking learners by intervention priority;
- improving onboarding and practical activation;
- targeting re-engagement campaigns;
- providing personalized learner guidance;
- evaluating retention strategies across behavioral segments;
- allocating limited retention resources more effectively.

The system is intended as a **decision-support tool**.

It should not be used as a fully automated intervention engine. Predictions should be combined with contextual information, business rules, and human review.

---

## Technical Skills Demonstrated

### Product Analytics

- Funnel Analysis
- Learning Journey Analysis
- Activation Gap Diagnosis
- Step-Level Analytics
- Retention Analytics
- Learner Behavior Analysis

### Machine Learning

- XGBoost
- Random Forest
- K-Means Clustering
- Feature Engineering
- Hyperparameter Evaluation
- Class Imbalance Handling
- PR-AUC Evaluation
- F2 Threshold Evaluation
- Feature Importance Analysis
- Model Robustness Analysis
- Holdout Validation

### ML Engineering

- Model Serialization
- Reusable Inference Functions
- Input Schema Validation
- Plumber REST API
- Shiny Application
- Single and Batch Prediction
- Capacity-Based Prioritization
- CSV Validation and Error Handling
- Automated Unit and Integration Testing
- Reproducible Environments

### Tools

- R
- Jupyter Notebook
- Shiny
- Plumber
- data.table
- dplyr
- tidyr
- ggplot2
- caret
- randomForest
- xgboost
- pROC
- MLmetrics
- testthat
- renv
- Git

---

## Project Structure

```text
stepik-product-analytics-completion-risk-ml/
├── api/
│   └── plumber.R
├── artifacts/
│   └── completion_risk_artifact.rds
├── data/
│   ├── raw/
│   ├── processed/
│   └── demo_batch_learners.csv
├── notebooks/
│   ├── 01_product_analysis_activation_gap.ipynb
│   ├── 02_behavioral_segmentation.ipynb
│   └── 03_completion_risk_modeling.ipynb
├── R/
│   ├── load_artifact.R
│   ├── validate_prediction_input.R
│   ├── predict_completion_risk.R
│   ├── build_retention_queue.R
│   └── batch_scoring.R
├── scripts/
│   ├── run_api.R
│   ├── generate_demo_batch.R
│   └── generate_demo_batch_with_errors.R
├── shiny/
│   └── app.R
├── tests/
│   └── testthat/
│       ├── setup.R
│       ├── test-api-integration.R
│       ├── test-api-batch-integration.R
│       ├── test-batch-scoring.R
│       ├── test-build-retention-queue.R
│       ├── test-predict-completion-risk.R
│       └── test-validate-prediction-input.R
├── .github/
│   └── workflows/
│       └── r-tests.yml
├── .gitignore
├── .Rprofile
├── LICENSE
├── README.md
└── renv.lock
```

---

## Reproducibility

The project includes an `renv.lock` file that records the R package versions used during development and validation.

To restore the project environment:

```r
install.packages("renv")
renv::restore()
```

The current local setup uses R 4.6.1. Exact package versions are recorded in `renv.lock`.

The model artifact is generated by:

```text
notebooks/03_completion_risk_modeling.ipynb
```

The training notebook does not need to be rerun when using the saved model for prediction.

Automated tests are also configured for continuous integration through GitHub Actions.

---

## Limitations

- The model is trained on data from one Stepik course.
- Predictions may not generalize directly to other courses or learning platforms.
- The features describe early learner behavior but do not capture motivation, external circumstances, or instructional quality.
- The F2-selected classification threshold is model-specific and should not be interpreted as a universal business intervention threshold.
- Capacity-based ranking identifies who should be reviewed first but does not determine whether an intervention will be effective.
- Predicted probabilities should support human decisions rather than replace them.
- Model performance and calibration should be monitored when the model is applied to new learner populations.

---

## Final Conclusion

This project demonstrates how product analytics, learning analytics, behavioral segmentation, machine learning, API engineering, and application development can be combined into a reusable learner-retention decision-support system.

The analysis identifies the transition from passive content consumption to practical engagement as a critical point in the learning journey.

The final XGBoost model uses behavioral signals from the first 10 course days to estimate completion probability and non-completion probability. The model is packaged as a reusable artifact, exposed through a Plumber API, and connected to a Shiny application for single-learner assessment and batch prioritization.

For retention operations, learners are ranked by predicted non-completion probability and selected according to available intervention capacity rather than an arbitrary risk cutoff.

The result is not only an analytical study, but also a working foundation for a practical EdTech ML decision-support product.
