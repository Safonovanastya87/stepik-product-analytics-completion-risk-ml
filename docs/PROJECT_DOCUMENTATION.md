# Full Project Documentation

Detailed analytical and technical documentation for the **Stepik EdTech Analytics and Learner Non-Completion Risk** project.

[← Back to main README](../README.md)

---

## Stepik EdTech Analytics and Learner Non-Completion Risk

## What This Project Does

This is an end-to-end EdTech analytics and machine-learning project based on learner activity data from the online learning platform Stepik.

The project starts with product and behavioral analysis and ends with a reusable prediction and prioritization system that can:

- estimate a learner's probability of course completion and non-completion;
- score one learner through a Shiny application;
- score many learners from an XLSX file;
- validate learner data before prediction;
- separate invalid XLSX rows from valid rows in the Shiny workflow;
- rank valid learners by predicted non-completion probability;
- return the Top N learners according to available retention capacity;
- expose the trained model through a Plumber REST API;
- write batch results to XLSX;
- run automated unit and integration tests.

The analyzed course is **Interactive Data Analysis in R**.

The main business question is:

> Why do learners fail to complete the course, and how early can learners with elevated non-completion risk be identified and prioritized for retention support?

The system is designed as a decision-support tool, not as a fully automated intervention engine.

---

## Quick Demo — Start Here

If you only want to see the final application working, this is the shortest path.

### 1. Clone the Repository

PowerShell / Terminal:

```bash
git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git
cd stepik-product-analytics-completion-risk-ml
```

### 2. Restore the R Environment

The project uses `renv`.

From the project root, open an R console.

First install `renv`:

```r
install.packages("renv")
```

After installation has completed, restore the project environment:

```r
renv::restore()
```

The project was developed with **R 4.6.1**.

### 3. Start the API

The Shiny application uses the local Plumber API, so start the API first.

```r
source("renv/activate.R")
source("scripts/run_api.R")
```

The API runs at:

```text
http://127.0.0.1:8001
```

Health endpoint:

```text
http://127.0.0.1:8001/health
```

Swagger documentation:

```text
http://127.0.0.1:8001/__docs__/
```

Keep this R console running.

### 4. Start the Shiny Application

Open a second R console in the project root:

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

It contains two workflows:

- **Single Learner**
- **Batch XLSX**

---

## How to Use the Shiny Application

### Single Learner

The **Single Learner** tab does not require a dataset.

Enter the learner features manually and run the assessment. The application validates the values and, for valid input, sends the learner profile to the Plumber API.

The main result is:

```text
Estimated non-completion probability
```

For example:

```text
98.2%
```

This means that the model estimates a 98.2% probability of non-completion for the supplied learner profile.

The interface intentionally emphasizes the continuous probability instead of turning it directly into an intervention decision.

### Batch XLSX

The **Batch XLSX** workflow is intended for scoring many learners at once.

Two ready-to-use demo files are included:

```text
data/demo_batch_learners.xlsx
data/demo_batch_learners_with_errors.xlsx
```

#### Valid Demo XLSX

`data/demo_batch_learners.xlsx` contains 100 anonymized learner feature records sampled from the finalized holdout test set after model development and final evaluation.

The records retain the original 10-day feature-engineering logic used by the model. Original Stepik learner identifiers are replaced with neutral demo IDs:

```text
10001 ... 10100
```

The valid demo is exported at the end of:

```text
notebooks/03_completion_risk_modeling.ipynb
```

It is generated only after model development and final holdout evaluation, so it is used for inference demonstration and does not influence model selection, tuning, or threshold analysis.

#### Demo XLSX with Validation Errors

`data/demo_batch_learners_with_errors.xlsx` is derived from the valid demo and intentionally contains selected invalid rows.

It can be regenerated from the project root with:

```r
source("scripts/generate_demo_batch_with_errors.R")
```

The file is used to demonstrate:

- row-level validation;
- partial scoring of valid learners;
- the **Rejected rows** view;
- downloadable validation errors.

#### Upload the File in Shiny

After starting the API and Shiny application:

1. Open the **Batch XLSX** tab.
2. Click **Browse**.
3. Select `data/demo_batch_learners.xlsx` or `data/demo_batch_learners_with_errors.xlsx`.
4. Review the XLSX preview.
5. Set **Learners to prioritize**.
6. Run the batch assessment.

With the current validation-error demo, an example result is:

```text
100 uploaded
97 scored
3 rejected
18 prioritized
```

This means:

- the workbook contained 100 learner rows;
- 97 rows passed validation and were scored;
- 3 rows were rejected;
- the 18 valid learners with the highest predicted non-completion probability were placed in the priority queue.

### Batch Output

The Batch workflow provides:

- **Priority intervention queue** — Top N valid learners ranked by non-completion probability;
- **Rejected rows** — displayed when invalid rows exist;
- **Download queue** — prioritized learners;
- **Download full results** — all successfully scored learners;
- **Download validation errors** — rejected rows and validation messages.

---

## XLSX Input Format

Each row represents one learner observed during the first 10 course days.

The XLSX file must contain these columns:

| Column | Meaning | Validation |
| --- | --- | --- |
| `user_id` | Learner identifier | Positive whole number |
| `n_passed_all` | Total passed course steps | Whole number, 0–198 |
| `n_viewed_all` | Total viewed steps | Non-negative whole number |
| `n_started_practical` | Practical-start events | Non-negative whole number |
| `n_passed_practical` | Practical steps passed | Whole number, 0–76 |
| `n_submissions` | Number of submissions | Non-negative whole number |
| `submission_correct_rate` | Share of correct submissions | 0–1 |
| `active_days` | Active days in the observation window | Whole number, 1–10 |
| `days_since_last_action` | Days since the learner's last action | Whole number, 0–9 |
| `score_per_active_day` | Score intensity per active day | 0–88 |
| `steps_per_active_day` | Passed-step activity per active day | 0–198 |

Important cross-field rules include:

- `n_passed_practical <= n_passed_all`;
- `n_passed_practical <= n_started_practical`;
- if `n_passed_practical > 0`, then `n_submissions > 0`;
- if `n_submissions > 0`, then `n_started_practical > 0`.

The authoritative implementation is:

```text
R/validate_prediction_input.R
```

---

## Business Problem

Online learning platforms often experience substantial learner drop-off before course completion.

This project investigates:

- where learners disengage during the course journey;
- which parts of the journey create the strongest friction;
- how engagement patterns differ across learners;
- which early behavioral signals are associated with eventual completion;
- how early non-completion probability can be estimated;
- how limited retention capacity can be allocated efficiently.

The prediction system is intended to support human decision-making. A high model score identifies a learner who should be reviewed earlier; it does not prove that a particular intervention will work.

---

## Project Workflow

```text
Product analytics
      ↓
Behavioral segmentation
      ↓
10-day feature engineering
      ↓
Completion-risk modeling
      ↓
Final holdout evaluation
      ↓
Reusable model artifact
      ↓
Plumber REST API
      ↓
Shiny / file-based inference
      ↓
Capacity-based learner prioritization
```

---

## Part 1 — Product Analytics and Activation Gap Analysis

The first analytical stage focuses on understanding learner behavior throughout the course.

It includes:

- funnel analysis;
- learning-journey reconstruction;
- step-level engagement analysis;
- practical-assignment analysis;
- learner-level behavioral profiling.

### Key Finding

The largest learner drop-off occurs before meaningful practical engagement.

Many learners consume content passively but never transition into practical work. This gap between content consumption and active learning is described as the **Activation Gap**.

This finding motivates the later focus on early practical activity, engagement intensity, and recency.

---

## Part 2 — Behavioral Segmentation

The second stage uses K-Means clustering to identify learner archetypes based on engagement and learning behavior.

| Segment | Description |
| --- | --- |
| Passive Users | Low engagement and minimal practical activity |
| Steady Learners | Consistent participation and moderate progress |
| Burst Learners | High-intensity engagement and strong productivity |

### Key Finding

Learners exhibit distinct behavioral patterns, and completion outcomes differ substantially across segments.

The segmentation stage is exploratory and descriptive. It complements the supervised model by showing that learners do not follow one uniform engagement pattern.

---

## Part 3 — Completion Risk Modeling

The modeling stage estimates eventual course-completion probability using behavioral signals observed during the first 10 course days.

Models evaluated include:

- Random Forest;
- XGBoost.

The model estimates:

```text
P(Completed)
```

Non-completion probability is derived as:

```text
Completion Risk = 1 - P(Completed)
```

The final operational implementation uses XGBoost.

### Model Validation

The modeling workflow includes:

- class-imbalance analysis;
- cross-validation;
- hyperparameter evaluation;
- PR-AUC-based model comparison;
- F2-score and false-positive-rate analysis;
- feature-importance analysis;
- dominant-feature ablation;
- engagement-only robustness checks;
- calibration diagnostics;
- final holdout evaluation.

The final holdout is kept separate from model development and is used only for the final unbiased evaluation.

### Classification Threshold vs. Retention Prioritization

This distinction is important.

The XGBoost model produces a continuous probability.

During technical model validation, a classification threshold of:

```text
P(Completed) = 0.116
```

was selected using the F2 score.

That threshold can be used for technical binary classification:

```text
P(Completed)
      ↓
threshold = 0.116
      ↓
Predicted Completed / Predicted Not Completed
```

However, it is not used as the business rule for intervention priority.

Retention prioritization is a separate decision:

```text
P(Not Completed)
      ↓
sort descending
      ↓
Top N according to available capacity
```

The fact that `0.116` produced the preferred validation trade-off does not make it an automatically justified intervention threshold.

Retention prioritization therefore uses relative risk ranking and available intervention capacity.

### Final Operational Model

The progress-aware XGBoost family produced the strongest overall predictive performance among the evaluated approaches.

For production inference, the project retains the selected XGBoost baseline model because additional tuning produced only marginal PR-AUC improvement while slightly worsening the preferred F2–false-positive-rate trade-off.

This choice favors a strong but comparatively simple operational model rather than selecting the most complex candidate solely because of a very small metric improvement.

---

## Trained Model Artifact

The production artifact is stored as:

```text
artifacts/completion_risk_artifact.rds
```

It contains the reusable operational model and the metadata required for inference:

```text
completion_risk_artifact.rds
├── model_raw
├── model_metadata
├── inference_settings
└── results
```

The artifact stores:

- the serialized XGBoost model;
- model metadata;
- required feature names;
- feature order;
- inference settings;
- selected evaluation information.

The training notebook does not need to be rerun for normal prediction.

Broader analytical model objects and result tables are stored separately:

```text
models/completion_risk_model_objects.rds
results/completion_risk_result_tables.rds
```

These support reproducibility and analysis but are not required by the normal prediction workflow.

---

## Inference Pipeline

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

For batch prioritization:

```text
Valid learner predictions
      ↓
sort by completion_risk descending
      ↓
assign risk_rank
      ↓
Top N
      ↓
Priority intervention queue
```

---

## Prediction Output

For every scored learner, the core inference output contains:

```text
completion_probability
completion_risk
```

Example:

```text
completion_probability = 0.28
completion_risk        = 0.72
```

This means:

```text
28% estimated probability of completion
72% estimated probability of non-completion
```

Technical model-level output can also include:

```text
classification_threshold
predicted_completion_status
```

These fields belong to model classification and diagnostics. They are not used as the operational intervention cutoff.

---

## Capacity-Based Priority Queue

The operational queue does not filter learners using an arbitrary fixed risk threshold.

Instead, it:

1. scores valid learners;
2. sorts them from highest to lowest `completion_risk`;
3. assigns `risk_rank`;
4. selects the first Top N learners.

Example:

| `risk_rank` | `user_id` | `completion_probability` | `completion_risk` |
| ---: | ---: | ---: | ---: |
| 1 | 1001 | 0.06 | 0.94 |
| 2 | 1002 | 0.24 | 0.76 |
| 3 | 1003 | 0.39 | 0.61 |

The operational question is:

> Which N learners should be reviewed first if the retention team can support only N interventions?

---

## Plumber REST API

The model is exposed through a Plumber API.

Implementation:

```text
api/plumber.R
```

### `GET /health`

Returns information about the loaded model and inference configuration.

Example fields include:

- `status`
- `model_loaded`
- `model_class`
- `required_feature_count`
- `observation_window_days`

### `POST /predict`

Scores one learner.

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

The current operational batch workflow is capacity-based; intervention priority is controlled through `top_n`, not through a business risk cutoff.

### Direct API vs. Shiny Batch Upload

The API expects valid learner records.

The Shiny batch workflow adds a user-facing preprocessing layer:

```text
uploaded XLSX
      ↓
row-level validation in Shiny
      ↓
valid rows   → API scoring
invalid rows → Rejected rows
```

This is why an XLSX containing a small number of invalid rows can still produce predictions for valid rows in the Shiny application.

---

## Main R Components

### `R/load_artifact.R`

Loads and validates the saved production artifact and restores the trained XGBoost booster.

### `R/validate_prediction_input.R`

Validates:

- required columns;
- numeric values;
- allowed ranges;
- selected cross-field consistency rules.

### `R/predict_completion_risk.R`

Runs the model and produces the completion and non-completion probability outputs used by downstream workflows.

### `R/build_retention_queue.R`

Sorts learners by descending non-completion probability, assigns `risk_rank`, and returns the requested Top N.

### `R/batch_scoring.R`

Provides reusable XLSX-based file scoring:

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

## File-Based Batch Scoring

File-based scoring can be run without the Shiny interface.

The executable script is:

```text
scripts/run_batch_scoring.R
```

The current demo configuration uses:

```text
data/demo_batch_learners.xlsx
```

and writes:

```text
outputs/completion_risk_predictions.xlsx
outputs/retention_queue.xlsx
```

Run:

```r
source("scripts/run_batch_scoring.R")
```

The current demo runner creates a Top-20 retention queue from the 100-row valid demo dataset.

### Example R Usage

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

## Demo Data

### Valid Demo

The ready-to-use valid demo is:

```text
data/demo_batch_learners.xlsx
```

It contains 100 anonymized records sampled from the finalized holdout set after all model-development decisions and final evaluation.

The file is exported at the end of:

```text
notebooks/03_completion_risk_modeling.ipynb
```

There is no separate synthetic valid-demo generator.

### Demo with Validation Errors

The validation-error demo is:

```text
data/demo_batch_learners_with_errors.xlsx
```

It is generated from the valid demo with:

```r
source("scripts/generate_demo_batch_with_errors.R")
```

The current file contains controlled invalid records for demonstrating validation behavior while leaving the remaining rows available for scoring.

---

## Automated Testing

The project uses `testthat`.

The automated suite covers:

- prediction input validation;
- range validation;
- cross-field validation;
- model prediction behavior;
- retention-queue ranking;
- Top-N capacity behavior;
- XLSX batch scoring;
- API integration;
- batch API integration.

Run all tests from the project root:

```r
source("renv/activate.R")

testthat::test_dir(
  "tests/testthat",
  reporter = "summary"
)
```

A successful run should complete with no failed tests.

The repository also contains a GitHub Actions workflow:

```text
.github/workflows/r-tests.yml
```

which runs the R test suite in CI.

---

## Project Structure

```text
stepik-product-analytics-completion-risk-ml/
│
├── .github/
│   └── workflows/
│       └── r-tests.yml
│
├── api/
│   └── plumber.R
│
├── artifacts/
│   └── completion_risk_artifact.rds
│
├── data/
│   ├── processed/
│   │   ├── cluster_features_model_base.csv
│   │   ├── completion_target_model_base.csv
│   │   ├── prediction_features_10d_model_base.csv
│   │   └── user_score_totals_10d.csv
│   │
│   ├── raw/
│   │   ├── event_data_train.csv
│   │   ├── event_data_train.zip
│   │   ├── submissions_data_train.csv
│   │   └── submissions_data_train.zip
│   │
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
├── models/
│   └── completion_risk_model_objects.rds
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
├── R/
│   ├── batch_scoring.R
│   ├── build_retention_queue.R
│   ├── load_artifact.R
│   ├── predict_completion_risk.R
│   └── validate_prediction_input.R
│
├── renv/
│   ├── .gitignore
│   ├── activate.R
│   └── settings.json
│
├── results/
│   └── completion_risk_result_tables.rds
│
├── scripts/
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

## Reproducibility

The project includes `renv.lock`, which records package versions used by the project.

Restore the environment in two steps.

First install `renv`:

```r
install.packages("renv")
```

Then restore the environment:

```r
renv::restore()
```

The current local setup uses R 4.6.1.

The production model artifact and valid demo are generated by:

```text
notebooks/03_completion_risk_modeling.ipynb
```

The notebook does not need to be rerun for normal inference.

---

## Key Findings

- The largest learner drop-off occurs before practical engagement begins.
- Practical activation is one of the strongest indicators of eventual course completion.
- Learners can be grouped into distinct behavioral segments with different completion outcomes.
- Behavior during the first 10 course days contains meaningful information for early risk prediction.
- The progress-aware XGBoost approach achieves the strongest overall predictive performance.
- The selected XGBoost baseline is retained as the operational model because further tuning provides only marginal PR-AUC improvement while slightly weakening the preferred F2–false-positive-rate trade-off.
- Engagement-only features remain informative after direct progress- and submission-related variables are removed.
- The trained model can be reused independently of the original modeling notebook.
- Continuous model probabilities can be translated into a capacity-aware retention workflow without inventing an unsupported business intervention threshold.

---

## Business Impact

Potential applications include:

- identifying learners with elevated non-completion probability;
- ranking learners by intervention priority;
- improving onboarding and practical activation;
- targeting re-engagement campaigns;
- providing personalized learner guidance;
- evaluating retention strategies across behavioral segments;
- allocating limited retention resources more effectively.

The system is intended as decision support.

Predictions should be combined with business context and human review rather than used as fully automated intervention decisions.

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
- XLSX Validation and Error Handling
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
- readxl
- writexl
- Git
- GitHub Actions

---

## Limitations

- The model is trained on data from one Stepik course.
- Predictions may not generalize directly to other courses or learning platforms.
- The input features describe early learner behavior but do not capture motivation, external circumstances, or instructional quality.
- The F2-selected classification threshold is model-specific and should not be interpreted as a universal intervention threshold.
- Capacity-based ranking identifies who should be reviewed first but does not determine whether an intervention will be effective.
- Predicted probabilities should support human decisions rather than replace them.
- Model performance and calibration should be monitored when the model is applied to new learner populations.

---

## Final Conclusion

This project demonstrates how product analytics, learning analytics, behavioral segmentation, machine learning, API engineering, and application development can be combined into a reusable learner-retention decision-support system.

The analysis identifies the transition from passive content consumption to practical engagement as a critical point in the learner journey.

The final XGBoost model uses behavioral signals from the first 10 course days to estimate completion probability and non-completion probability.

The model is packaged as a reusable artifact, exposed through a Plumber API, and connected to a Shiny application that supports both single-learner assessment and batch prioritization.

For retention operations, learners are ranked by predicted non-completion probability and selected according to available intervention capacity rather than an arbitrary business risk cutoff.

The valid portfolio demo now uses anonymized real feature rows sampled from the finalized holdout set after model development and final evaluation, while a separate derived XLSX demonstrates validation-error handling.

The result is not only an analytical study, but also a working foundation for a practical EdTech machine-learning decision-support product.

---

[← Back to main README](../README.md)
