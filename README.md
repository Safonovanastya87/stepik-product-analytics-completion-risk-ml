# Stepik Product Analytics & Completion Risk ML

End-to-end data science project for **early detection of course non-completion risk** using learner activity data from Stepik.

The project combines product analytics, behavioral segmentation, machine learning, model deployment, and automated testing in a reproducible R workflow.

## Project Goal

The main objective is to identify learners with an elevated risk of not completing a course based on their behavior during the **first 10 days**.

The resulting risk score can be used to prioritize learners for early retention interventions.

## Project Workflow

The project covers the full data science lifecycle:

1. **Exploratory and product analytics**
   - learner activity analysis;
   - activation-gap analysis;
   - behavioral patterns related to course completion.

2. **Learner segmentation**
   - feature engineering from LMS events;
   - K-Means clustering;
   - interpretation of learner behavior profiles.

3. **Completion risk modeling**
   - Random Forest;
   - XGBoost;
   - cross-validation and model tuning;
   - evaluation with **PR-AUC** and **F2-score**.

4. **Production inference**
   - reproducible model artifact;
   - single-learner prediction;
   - batch prediction;
   - validation and separation of invalid input rows.

5. **Retention prioritization**
   - ranking learners by predicted non-completion risk;
   - Top-N prioritization;
   - capacity-based retention queue.

6. **Deployment and quality assurance**
   - REST API with Plumber;
   - interactive Shiny application;
   - unit and integration tests;
   - GitHub Actions CI.

## Tech Stack

**Language**

- R

**Data & Analytics**

- data.table
- dplyr
- tidyr
- lubridate
- ggplot2
- corrplot
- cluster
- mclust
- fpc

**Machine Learning**

- caret
- randomForest
- xgboost
- pROC
- PRROC

**Deployment**

- plumber
- Shiny

**Reproducibility & Testing**

- renv
- testthat
- GitHub Actions

## Repository Structure

```text
.
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
│   ├── demo_batch_learners.csv
│   └── demo_batch_learners_with_errors.csv
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
│   ├── completion_risk_predictions.csv
│   └── retention_queue.csv
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

The repository contains small demo datasets for testing the batch prediction workflow. Larger source datasets and generated outputs are not tracked in Git.

## Quick Start

### 1. Clone the repository

**PowerShell / Terminal:**

```bash
git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git
cd stepik-product-analytics-completion-risk-ml
```

### 2. Install R

The project was developed with **R 4.6.x**.

Using the same R version is recommended for maximum reproducibility.

### 3. Install `renv`

If `renv` is not installed yet:

**R console:**

```r
install.packages("renv")
```

### 4. Restore the project environment

From the project root:

**R console:**

```r
renv::restore()
```

This installs the package versions recorded in `renv.lock`.

### Windows note

Some R packages may need to be compiled from source if a compatible binary is unavailable.

In that case, install the appropriate **Rtools** version for your R installation and run:

**R console:**

```r
renv::restore()
```

again.

Rtools is not required when all required packages can be installed as binaries.

## Run the REST API

From the project root:

**R console:**

```r
source("renv/activate.R")
source("scripts/run_api.R")
```

The API loads the saved model artifact and exposes the completion-risk prediction endpoint through Plumber.

## Run the Shiny Application

Open a second R console while the API remains running.

**R console:**

```r
source("renv/activate.R")
shiny::runApp("shiny", launch.browser = TRUE)
```

The application supports:

- **Single Learner** prediction;
- **Batch CSV** prediction;
- input validation;
- separation of invalid records;
- completion and non-completion probability output;
- learner risk ranking;
- capacity-based retention prioritization.

## Demo Batch Files

Two ready-to-use examples are included:

```text
data/demo_batch_learners.csv
data/demo_batch_learners_with_errors.csv
```

`demo_batch_learners.csv` contains valid example observations.

`demo_batch_learners_with_errors.csv` can be used to demonstrate batch input validation and handling of invalid rows.

## Model Artifact

The production inference pipeline uses:

```text
artifacts/completion_risk_artifact.rds
```

The artifact contains the components required to reproduce prediction behavior without retraining the model.

## Tests

Run the automated test suite from the project root:

**R console:**

```r
testthat::test_dir("tests/testthat")
```

The tests cover key inference behavior, including:

- prediction output structure;
- valid probability ranges;
- required feature validation;
- single and batch prediction behavior;
- API-related integration checks.

The test suite is also executed automatically through **GitHub Actions**.

## Reproducibility

The repository uses `renv` to keep the R package environment reproducible.

A clean setup should therefore require only:

**R console:**

```r
install.packages("renv")
renv::restore()
```

followed by the API and Shiny startup commands.

## Documentation

For the detailed analytical workflow, modeling decisions, feature engineering, validation logic, and deployment design, see:

[`docs/PROJECT_DOCUMENTATION.md`](docs/PROJECT_DOCUMENTATION.md)