# Full Project Documentation

Detailed analytical and technical documentation for the  

**Stepik EdTech Analytics and Learner Non-Completion Risk** project.

← [Back to main README](../README.md)

---

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

## What This Project Does

This is an end-to-end EdTech analytics and machine learning project based on learner activity data from the online learning platform **Stepik**.

The project starts with product and behavioral analysis and ends with a working prediction system that can:

- estimate a learner's probability of course non-completion;

- score one learner manually in a Shiny application;

- score many learners from a XLSX file;

- validate learner data before prediction;

- separate invalid XLSX rows from valid rows in the Shiny workflow;

- rank valid learners from highest to lowest predicted non-completion probability;

- return the **Top N learners** according to available retention capacity;

- expose the trained model through a Plumber REST API;

- run automated unit and integration tests.

The analyzed course is **Interactive Data Analysis in R**.

The main business question is:

> Why do learners fail to complete the course, and how early can learners with elevated non-completion risk be identified and prioritized for retention support?

---

# Quick Demo — Start Here

If you only want to see the final application working, this is the shortest path.

## 1. Clone the Repository

PowerShell / Terminal:

```bash

git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git

cd stepik-product-analytics-completion-risk-ml

```

## 2. Restore the R Environment

The project uses `renv`.

From the project root:

R console:

```r

install.packages("renv")

renv::restore()

```

The project was developed with **R 4.6.1**.

## 3. Start the API

The Shiny application uses the local Plumber API, so start the API first.

From the project root:

R console:

```r

source("renv/activate.R")

source("scripts/run_api.R")

```

The API runs at:

```text

http://127.0.0.1:8001

```

You can check that it is running by opening:

```text

http://127.0.0.1:8001/health

```

## 4. Start the Shiny Application

Open a second R console in the project root and run:

R console:

```r

source("renv/activate.R")

shiny::runApp(
"shiny",
host = "127.0.0.1",
port = 3838,
launch.browser = TRUE
)

```

The application runs at:

```text

http://127.0.0.1:3838

```

The application contains two workflows:

```text

Single Learner

Batch XLSX

```

---

# How to Use the Shiny Application

## Single Learner

The **Single Learner** tab does not require a dataset.

Enter the learner features manually in the form and run the prediction.

The application returns:

```text

Estimated non-completion probability

```

Example:

```text

98.2%

```

This means that the model estimates a **98.2% probability of non-completion** for the entered learner profile.

The interface intentionally shows the continuous probability instead of automatically labeling a learner as "high risk" or "low risk".

![Single Learner prediction](images/shiny_single.png)

---

## Batch XLSX

The **Batch XLSX** workflow is intended for scoring many learners at once.

You can either:

1. generate the provided demo data;

2. or upload your own XLSX that follows the required schema.

### Option A — Generate a Valid Demo XLSX

From the project root:

R console:

```r

source("scripts/generate_demo_batch.R")

```

This creates:

```text

data/demo_batch_learners.xlsx

```

Use this file to demonstrate the normal batch-scoring workflow.

### Option B — Generate a Demo XLSX Containing Validation Errors

Run in the R console:

```r

source("scripts/generate_demo_batch_with_errors.R")

```

This creates:

```text

data/demo_batch_learners_with_errors.xlsx

```

This file intentionally contains invalid learner rows and can be used to demonstrate:

- row-level validation;

- partial scoring of valid learners;

- the **Rejected rows** view;

- downloadable XLSX validation errors.

### Upload the File in Shiny

After starting the API and Shiny application:

1. open the **Batch XLSX** tab;

2. click **Browse** in the XLSX upload field;

3. select `data/demo_batch_learners.xlsx` or `data/demo_batch_learners_with_errors.xlsx`;

4. review the XLSX preview;

5. set **Learners to prioritize**;

6. run the batch prediction.

For example:

```text

100 uploaded

97 scored

3 rejected

18 prioritized

```

means:

- the XLSX contained 100 rows;

- 97 rows passed validation and were scored;

- 3 rows were rejected;

- the 18 learners with the highest predicted non-completion probability were placed in the priority queue.

![Batch learner prioritization](images/shiny_batch.png)

### Batch Output

The Batch workflow provides:

- **Priority intervention queue** — Top N valid learners ranked by non-completion probability;

- **Rejected rows** — displayed only when invalid rows exist;

- **Download queue** — prioritized learners;

- **Download full results** — all successfully scored learners;

- **Download validation errors** — rejected rows and validation messages.

Large result tables use internal scrolling so the full web page remains compact.

---

# XLSX Input Format

Each row represents one learner observed during the **first 10 course days**.

The XLSX file must contain these columns:

| Column | Meaning | Validation |

|---|---|---|

| `user_id` | Learner identifier | Positive whole number |

| `n_passed_all` | Total passed course steps | Whole number, 0–198 |

| `n_viewed_all` | Total viewed steps | Non-negative whole number |

| `n_started_practical` | Practical steps started | Non-negative whole number |

| `n_passed_practical` | Practical steps passed | Whole number, 0–76 |

| `n_submissions` | Number of submissions | Non-negative whole number |

| `submission_correct_rate` | Share of correct submissions | 0–1 |

| `active_days` | Active days in the observation window | Whole number, 1–10 |

| `days_since_last_action` | Days since the learner's last action | Whole number, 0–9 |

| `score_per_active_day` | Score intensity per active day | 0–88 |

| `steps_per_active_day` | Step activity per active day | 0–198 |

Important cross-field rules include:

- `n_passed_practical <= n_passed_all`;

- `n_passed_practical <= n_started_practical`;

- if `n_passed_practical > 0`, then `n_submissions > 0`;

- if `n_submissions > 0`, then `n_started_practical > 0`.

The validation code in:

```text

R/validate_prediction_input.R

```

is the authoritative implementation.

---

# Business Problem

Online learning platforms often experience substantial learner drop-off before course completion.

The project investigates:

- where learners disengage during the course journey;

- which course steps create the strongest friction;

- how engagement patterns differ across learners;

- which learners are most likely to complete the course;

- how early non-completion probability can be estimated;

- how limited retention capacity can be allocated efficiently.

The system is intended as a **decision-support tool**, not as a fully automated intervention engine.

---

# Project Workflow

The project combines analytical and engineering stages:

```text

Product analytics

      ↓

Behavioral segmentation

      ↓

Completion-risk modeling

      ↓

Reusable inference

      ↓

Plumber REST API

      ↓

Shiny application

      ↓

Capacity-based learner prioritization

```

---

# Part 1 — Product Analytics and Activation Gap Analysis

The first stage focuses on understanding learner behavior throughout the course.

The analysis includes:

- funnel analysis;

- learning journey reconstruction;

- step-level engagement analysis;

- practical assignment analysis;

- learner-level behavioral profiling.

## Key Finding

The largest learner drop-off occurs before meaningful practical engagement.

Many learners consume content passively but never transition into practical assignments.

This gap between content consumption and active learning is defined as the **Activation Gap**.

---

# Part 2 — Behavioral Segmentation

The second stage uses K-Means clustering to identify learner archetypes based on engagement and learning behavior.

| Segment | Description |

|---|---|

| Passive Users | Low engagement and minimal practical activity |

| Steady Learners | Consistent participation and moderate progress |

| Burst Learners | High-intensity engagement and strong productivity |

## Key Finding

Learners exhibit distinct behavioral patterns, and completion outcomes differ substantially across segments.

---

# Part 3 — Completion Risk Modeling

The modeling stage estimates course completion probability using behavioral signals observed during the **first 10 course days**.

Models evaluated:

- Random Forest;

- XGBoost.

The final prediction target is:

```text

P(Completed)

```

Non-completion probability is derived as:

```text

Completion Risk = 1 - P(Completed)

```

The final implementation uses XGBoost.

## Model Validation

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

---

# Classification Threshold vs. Retention Prioritization

This distinction is important.

The XGBoost model produces a **continuous probability**.

During model validation, the classification threshold:

```text

P(Completed) = 0.116

```

was selected using the F2 score.

That threshold is used for technical binary classification:

```text

Predicted Completed

Predicted Not Completed

```

However, the threshold is **not used to define intervention priority**.

These are two separate decisions.

## Model Classification

```text

P(Completed)

      ↓

threshold = 0.116

      ↓

Completed / Not Completed

```

## Retention Prioritization

```text

P(Not Completed)

      ↓

sort descending

      ↓

Top N according to available capacity

```

The fact that `0.116` produced the preferred validation trade-off does not make it an automatically justified business intervention threshold.

For this reason, the Shiny application does not use the model classification threshold as the operational rule for deciding who should receive retention support.

Retention prioritization is based on **relative risk ranking and available intervention capacity**.

---

# Trained Model Artifact

The trained model is stored as:

```text

artifacts/completion_risk_artifact.rds

```

The artifact contains:

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

The training notebook does not need to be rerun to make predictions.

---

# Inference Pipeline

The reusable inference workflow is:

```text

Learner data

      ↓

Input validation

      ↓

XGBoost prediction

      ↓

Completion probability

      ↓

Non-completion probability

```

For batch scoring:

```text

Valid learner predictions

      ↓

sort by completion_risk descending

      ↓

Top N

      ↓

Priority intervention queue

```

---

# Prediction Output

For every scored learner, the pipeline returns:

```text

completion_probability

completion_risk

```

Example:

```text

completion_probability = 0.28

completion_risk        = 0.72

```

This means:

```text

28% estimated probability of completion

72% estimated probability of non-completion

```

Technical model output can also include:

```text

classification_threshold

predicted_completion_status

```

These fields are retained for model-level classification and diagnostics but are not used as the operational intervention cutoff.

---

# Capacity-Based Priority Queue

The queue does **not** filter learners using an arbitrary fixed risk threshold.

Instead, it:

1. scores all valid learners;

2. sorts them from highest to lowest `completion_risk`;

3. assigns `risk_rank`;

4. selects the first `Top N` learners.

Example:

| risk_rank | user_id | completion_probability | completion_risk |

|---:|---:|---:|---:|

| 1 | 1001 | 0.06 | 0.94 |

| 2 | 1002 | 0.24 | 0.76 |

| 3 | 1003 | 0.39 | 0.61 |

The operational question is therefore:

> Which N learners should be reviewed first if the retention team can support only N interventions?

---

# Plumber REST API

The model is exposed through a Plumber API.

The implementation is in:

```text

api/plumber.R

```

## GET `/health`

Returns information about the loaded model and inference configuration.

Example fields:

```text

status

model_loaded

model_class

required_feature_count

observation_window_days

```

## POST `/predict`

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

## POST `/predict-batch`

Scores multiple learners and returns a capacity-based priority queue.

Conceptual request:

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

Conceptual response:

```json

{

  "learner_count": 1,

  "queue_count": 1,

  "top_n": 1,

  "predictions": [],

  "retention_queue": []

}

```

`min_risk` is intentionally absent from the current batch API contract.

### Important Difference Between Direct API and Shiny Batch Upload

The API itself is strict: the request must contain valid learner data.

The Shiny Batch workflow adds a user-facing preprocessing layer:

```text

uploaded XLSX

    ↓

row-level validation in Shiny

    ↓

valid rows → API scoring

invalid rows → Rejected rows

```

This is why a XLSX containing a few invalid rows can still produce predictions for valid rows in the Shiny application.

---

# Main R Components

## `R/load_artifact.R`

Loads and validates the saved model artifact and restores the trained XGBoost booster.

## `R/validate_prediction_input.R`

Validates:

- feature structure;

- required columns;

- numeric types;

- allowed ranges;

- cross-field consistency.

## `R/predict_completion_risk.R`

Runs the model and produces:

```text

completion_probability

completion_risk

classification_threshold

predicted_completion_status

```

## `R/build_retention_queue.R`

Sorts learners by descending non-completion probability, assigns `risk_rank`, and returns the requested Top N.

## `R/batch_scoring.R`

Provides file-based scoring:

```text

XLSX

 ↓

model prediction

 ↓

priority queue

 ↓

predictions XLSX + queue XLSX

```

---

# Example R Usage

```r

source("R/load_artifact.R")

source("R/validate_prediction_input.R")

source("R/predict_completion_risk.R")

source("R/build_retention_queue.R")

loaded_model <- load_completion_risk_artifact()

new_learners <- readxl::read_excel(

  "path/to/new_learner_features.xlsx"

)

predictions <- predict_completion_risk(

  data = new_learners,

  loaded_model = loaded_model

)

retention_queue <- build_retention_queue(

  predictions = predictions,

  id_col = "user_id",

  top_n = 10

)

```

---

# Demo Data

Two scripts are provided specifically so the final application can be tested without preparing external data manually.

## Valid Demo

```text

scripts/generate_demo_batch.R

```

Run in the R console:

```r

source("scripts/generate_demo_batch.R")

```

Output:

```text

data/demo_batch_learners.xlsx

```

## Demo with Validation Errors

```text

scripts/generate_demo_batch_with_errors.R

```

Run in the R console:

```r

source("scripts/generate_demo_batch_with_errors.R")

```

Output:

```text

data/demo_batch_learners_with_errors.xlsx

```

The error demo includes controlled invalid rows to demonstrate validation behavior.

---

# Automated Testing

The project uses `testthat`.

The automated suite covers:

- prediction input validation;

- range validation;

- cross-field validation;

- model prediction behavior;

- retention-queue ranking;

- Top N capacity behavior;

- batch scoring;

- API integration;

- batch API integration.

Run all tests from the project root:

R console:

```r

source("renv/activate.R")

testthat::test_dir(
"tests/testthat",
reporter = "summary"
)

```

A successful run should complete with no failed tests.

The project also contains a GitHub Actions workflow:

```text

.github/workflows/r-tests.yml

```

which runs the R test suite in CI.

---

# Project Structure

```text

stepik-product-analytics-completion-risk-ml/

├── .github/
│   └── workflows/
│       └── r-tests.yml
│
├── R/
│   ├── batch_scoring.R
│   ├── build_retention_queue.R
│   ├── load_artifact.R
│   ├── predict_completion_risk.R
│   └── validate_prediction_input.R
│
├── api/
│   └── plumber.R
│
├── artifacts/
│   └── completion_risk_artifact.rds
│
├── data/
│   ├── demo_batch_learners.xlsx
│   └── demo_batch_learners_with_errors.xlsx
│
├── docs/
│   ├── images/
│   │   ├── .gitkeep
│   │   ├── shiny_batch.png
│   │   └── shiny_single.png
│   └── PROJECT_DOCUMENTATION.md
│
├── notebooks/
│   ├── 01_product_analysis_activation_gap.ipynb
│   ├── 02_behavioral_segmentation.ipynb
│   └── 03_completion_risk_modeling.ipynb
│
├── outputs/
│   ├── completion_risk_predictions.xlsx
│   └── retention_queue.xlsx
│
├── renv/
│   ├── .gitignore
│   ├── activate.R
│   └── settings.json
│
├── scripts/
│   ├── generate_demo_batch.R
│   ├── generate_demo_batch_with_errors.R
│   ├── run_api.R
│   └── run_batch_scoring.R
│
├── shiny/
│   └── app.R
│
├── tests/
│   └── testthat/
│       ├── setup.R
│       ├── test-api-batch-integration.R
│       ├── test-api-integration.R
│       ├── test-batch-scoring.R
│       ├── test-build-retention-queue.R
│       ├── test-predict-completion-risk.R
│       └── test-validate-prediction-input.R
│
├── .Rprofile
├── .gitignore
├── LICENSE
├── README.md
└── renv.lock

```

---

# Reproducibility

The project includes `renv.lock`, which records the package versions used by the project.

Restore the environment with:

```r

install.packages("renv")

renv::restore()

```

The current local setup uses **R 4.6.1**.

The trained model artifact is generated by:

```text

notebooks/03_completion_risk_modeling.ipynb

```

The notebook does not need to be rerun for normal inference.

---

# Key Findings

- The largest learner drop-off occurs before practical engagement begins.

- Practical activation is one of the strongest indicators of eventual course completion.

- Learners can be grouped into distinct behavioral segments with different completion outcomes.

- Behavior during the first 10 course days contains meaningful information for early risk prediction.

- The progress-aware XGBoost approach achieves the strongest overall predictive performance.

- XGB Baseline is retained as the final operational model because further tuning provides only a marginal PR-AUC improvement while producing a slightly less favorable F2–FPR trade-off.

- Engagement-only features remain informative after direct progress- and submission-related variables are removed.

- The trained model can be reused independently of the original modeling notebook.

- Continuous model probabilities can be translated into a capacity-aware retention workflow without inventing an unsupported business risk threshold.

---

# Business Impact

Potential applications include:

- identifying learners with elevated non-completion probability;

- ranking learners by intervention priority;

- improving onboarding and practical activation;

- targeting re-engagement campaigns;

- providing personalized learner guidance;

- evaluating retention strategies across behavioral segments;

- allocating limited retention resources more effectively.

The system is intended as **decision support**.

Predictions should be combined with business context and human review rather than used as fully automated intervention decisions.

---

# Technical Skills Demonstrated

## Product Analytics

- Funnel Analysis

- Learning Journey Analysis

- Activation Gap Diagnosis

- Step-Level Analytics

- Retention Analytics

- Learner Behavior Analysis

## Machine Learning

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

## ML Engineering

- Model Serialization

- Reusable Inference Functions

- Input Schema Validation

- Plumber REST API

- Shiny Application

- Single and Batch Prediction

- Capacity-Based Prioritization

- XLSX Validation and Error Handling

- Automated Unit and Integration Testing

- Reproducible Environments

## Tools

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

- readxl

- writexl

- Git

- GitHub Actions

---

# Limitations

- The model is trained on data from one Stepik course.

- Predictions may not generalize directly to other courses or learning platforms.

- The input features describe early learner behavior but do not capture motivation, external circumstances, or instructional quality.

- The F2-selected classification threshold is model-specific and should not be interpreted as a universal intervention threshold.

- Capacity-based ranking identifies who should be reviewed first but does not determine whether an intervention will be effective.

- Predicted probabilities should support human decisions rather than replace them.

- Model performance and calibration should be monitored when the model is applied to new learner populations.

---

# Final Conclusion

This project demonstrates how product analytics, learning analytics, behavioral segmentation, machine learning, API engineering, and application development can be combined into a reusable learner-retention decision-support system.

The analysis identifies the transition from passive content consumption to practical engagement as a critical point in the learner journey.

The final XGBoost model uses behavioral signals from the first 10 course days to estimate completion probability and non-completion probability.

The model is packaged as a reusable artifact, exposed through a Plumber API, and connected to a Shiny application that supports both single-learner assessment and batch prioritization.

For retention operations, learners are ranked by predicted non-completion probability and selected according to available intervention capacity rather than an arbitrary risk cutoff.

The result is not only an analytical study, but also a working foundation for a practical EdTech machine learning decision-support product.

---

← [Back to main README](../README.md)