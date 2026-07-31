# Stepik EdTech Analytics and Completion Risk Prediction System

![R](https://img.shields.io/badge/R-4.6.1-blue)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange)
![Machine Learning](https://img.shields.io/badge/ML-XGBoost-green)
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
- a reusable prediction pipeline;
- automated input validation and testing.

The project analyzes learner behavior in the course **Interactive Data Analysis in R** and addresses the central business question:

> Why do learners fail to complete the course, and how early can at-risk learners be identified?

The project moves beyond retrospective analysis by providing a reusable inference pipeline that can score new learner data and generate a ranked retention queue.

---

## Business Problem

Online learning platforms often experience substantial learner drop-off before course completion.

The project investigates:

- where learners disengage during the course journey;
- which course steps create the strongest friction;
- how engagement patterns differ across learners;
- which learners are most likely to complete the course;
- how early non-completion risk can be estimated;
- how retention teams can prioritize limited intervention capacity.

The goal is to move from retrospective completion reporting toward proactive learner-retention analytics.

---

## Dataset

The project uses anonymized learner activity data from the Stepik platform.

Two public datasets are analyzed:

- **Event Data** — content views, discoveries, practical starts, and passed assignments;
- **Submission Data** — practical assignment attempts and submission outcomes.

Together, these datasets allow the reconstruction of learner journeys, engagement patterns, practical activity, and completion trajectories.

---

## Project Workflow

The project consists of four connected layers:

```text
Product analytics
        ↓
Behavioral segmentation
        ↓
Completion-risk modeling
        ↓
Reusable prediction and retention pipeline
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

The modeling stage estimates the probability of course completion using behavioral signals observed during the first 10 days of learner activity.

Models evaluated:

- Random Forest;
- XGBoost.

The final prediction target is:

```text
P(Completed)
```

The operational non-completion risk is calculated as:

```text
Completion Risk = 1 − P(Completed)
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
Non-completion risk
        ↓
Ranked retention queue
```

### Required Prediction Features

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

### Prediction Output

For every learner, the pipeline returns:

```text
completion_probability
completion_risk
```

Example:

```text
completion_probability = 0.28
completion_risk        = 0.72
```

This represents a 28% estimated probability of course completion and a 72% estimated risk of non-completion.

---

## Retention Queue

The prediction output can be converted into a ranked retention queue.

The queue:

1. filters learners above a selected risk threshold;
2. sorts learners from highest to lowest non-completion risk;
3. assigns a `risk_rank`;
4. optionally returns only the highest-priority learners.

Example output:

| user_id | risk_rank | completion_probability | completion_risk |
|---:|---:|---:|---:|
| 1001 | 1 | 0.06 | 0.94 |
| 1002 | 2 | 0.24 | 0.76 |
| 1003 | 3 | 0.39 | 0.61 |

This output is designed as decision support for learner-retention teams.

---

## Production-Style R Components

The reusable inference logic is separated from the exploratory notebooks.

### `R/load_artifact.R`

Loads and validates the saved model artifact and restores the trained XGBoost booster.

### `R/validate_prediction_input.R`

Checks that prediction data:

- is a non-empty data frame;
- contains every required feature;
- contains numeric values;
- contains no missing or infinite values;
- follows the feature order expected by the model.

### `R/predict_completion_risk.R`

Runs the trained model and adds:

```text
completion_probability
completion_risk
```

to the input learner data.

### `R/build_retention_queue.R`

Filters and ranks learners according to their estimated non-completion risk.

---

## Example Usage

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
  min_risk = 0.50,
  top_n = 100
)
```

---

## Automated Testing

The project uses `testthat` to verify the reusable inference components.

The current automated tests check that:

- valid prediction data is accepted;
- the validated output is a data frame;
- the expected number of rows is preserved;
- the model features are returned in the correct order;
- missing model features are rejected;
- non-numeric feature values are rejected.

Run the tests with:

```r
testthat::test_dir(
  "tests/testthat"
)
```

Current test result:

```text
FAIL 0 | WARN 0 | SKIP 0 | PASS 5
```

Additional tests for model predictions and retention-queue ranking can be added as the inference layer develops further.

---

## Key Findings

- The largest learner drop-off occurs before practical engagement begins.
- Practical activation is one of the strongest indicators of eventual course completion.
- Learners can be grouped into distinct behavioral segments with different completion outcomes.
- Behavior during the first 10 days contains meaningful information for early risk prediction.
- The progress-aware XGBoost approach achieves the strongest overall predictive performance.
- XGB Baseline is retained as the final operational model because further tuning provides only a marginal PR-AUC improvement while producing a slightly less favorable F2–FPR trade-off.
- Engagement-only features remain informative after direct progress- and submission-related variables are removed.
- Product analytics, behavioral segmentation, and predictive modeling can be combined into a unified learner-retention framework.
- The trained model can be reused independently of the original modeling notebook.

---

## Business Impact

The project demonstrates how educational-platform data can support proactive and capacity-aware learner-retention strategies.

Potential applications include:

- identifying learners with elevated non-completion risk;
- ranking learners by intervention priority;
- improving onboarding and practical activation;
- targeting re-engagement campaigns;
- providing personalized learner guidance;
- evaluating retention strategies across behavioral segments;
- allocating limited retention resources more effectively.

The system is intended as a decision-support tool.

It should not be used as a fully automated decision or intervention engine. Predictions should be combined with contextual information, business rules, and human review.

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
- Feature Importance Analysis
- Model Robustness Analysis
- Holdout Validation

### ML Engineering

- Model Serialization
- Reusable Inference Functions
- Input Schema Validation
- Batch-Compatible Prediction
- Business Rule Integration
- Retention Queue Generation
- Automated Testing
- Reproducible Environments

### Tools

- R
- Jupyter Notebook
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
├── artifacts/
│   └── completion_risk_artifact.rds
├── data/
│   ├── raw/
│   └── processed/
├── notebooks/
│   ├── 01_product_analysis_activation_gap.ipynb
│   ├── 02_behavioral_segmentation.ipynb
│   └── 03_completion_risk_modeling.ipynb
├── R/
│   ├── load_artifact.R
│   ├── validate_prediction_input.R
│   ├── predict_completion_risk.R
│   └── build_retention_queue.R
├── tests/
│   └── testthat/
│       ├── setup.R
│       └── test-validate-prediction-input.R
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

---

## Limitations

- The model is trained on data from one Stepik course.
- Predictions may not generalize directly to other courses or learning platforms.
- The features describe early learner behavior but do not capture motivation, external circumstances, or instructional quality.
- Predicted probabilities should support human decisions rather than replace them.
- Model performance and calibration should be monitored when the model is applied to new learner populations.

---

## Final Conclusion

This project demonstrates how product analytics, learning analytics, behavioral segmentation, and machine learning can be combined into a reusable learner-retention system.

The analysis identifies the transition from passive content consumption to practical engagement as the most critical point in the learning journey.

The final XGBoost model uses early behavioral signals to estimate completion probability and non-completion risk. The model is packaged as a reusable artifact and connected to a validated inference pipeline that can score new learner data and generate a ranked retention queue.

The result is not only an analytical study, but also a foundation for a practical EdTech decision-support product.
