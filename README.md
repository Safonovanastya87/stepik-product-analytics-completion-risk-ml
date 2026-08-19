# Stepik Product Analytics & Completion Risk ML

End-to-end data science project for **early detection of course non-completion risk** using learner activity data from Stepik.

The project combines product analytics, behavioral segmentation, machine learning, model deployment, and automated testing in a reproducible R workflow.

## Project Goal

The main objective is to identify learners with an elevated risk of not completing a course based on their behavior during the **first 10 days**.

The resulting risk score can be used to prioritize learners for early retention interventions.

## Project Workflow

The project covers the full data science lifecycle:

1. **Exploratory and product analytics**

   * learner activity analysis;
   * activation-gap analysis;
   * behavioral patterns related to course completion.

2. **Learner segmentation**

   * feature engineering from LMS events;
   * K-Means clustering;
   * interpretation of learner behavior profiles.

3. **Completion risk modeling**

   * Random Forest;
   * XGBoost;
   * cross-validation and model tuning;
   * evaluation with **PR-AUC** and **F2-score**.

4. **Production inference**

   * reproducible model artifact;
   * single-learner prediction;
   * batch prediction;
   * validation and separation of invalid input rows.

5. **Retention prioritization**

   * ranking learners by predicted non-completion risk;
   * Top-N prioritization;
   * capacity-based retention queue.

6. **Deployment and quality assurance**

   * REST API with Plumber;
   * interactive Shiny application;
   * unit and integration tests;
   * GitHub Actions CI.

## Tech Stack

**Language**

* R

**Data & Analytics**

* data.table
* dplyr
* tidyr
* lubridate
* ggplot2
* corrplot
* cluster
* mclust
* fpc

**Machine Learning**

* caret
* randomForest
* xgboost
* pROC
* PRROC

**Deployment**

* plumber
* Shiny

**Reproducibility & Testing**

* renv
* testthat
* GitHub Actions

## Repository Structure

```text
.
├── artifacts/
│   └── completion_risk_artifact.rds
│
├── data/
│   ├── demo_batch_learners.csv
│   └── demo_batch_learners_with_errors.csv
│
├── scripts/
│   ├── run_api.R
│   └── run_shiny.R
│
├── tests/
│
├── renv/
├── renv.lock
├── .github/
│   └── workflows/
│
├── README.md
└── PROJECT_DOCUMENTATION.md
```

The repository contains small demo datasets for testing the batch prediction workflow. Larger source datasets and generated outputs are not tracked in Git.

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git
cd stepik-product-analytics-completion-risk-ml
```

### 2. Install R

The project was developed with **R 4.6.0**.

Using the same R version is recommended for maximum reproducibility.

### 3. Install `renv`

If `renv` is not installed yet:

```r
install.packages("renv")
```

### 4. Restore the project environment

From the project root:

```r
renv::restore()
```

This installs the package versions recorded in `renv.lock`.

### Windows note

Some R packages may need to be compiled from source if a compatible binary is unavailable.

In that case, install the appropriate **Rtools** version for your R installation and run:

```r
renv::restore()
```

again.

Rtools is not required when all required packages can be installed as binaries.

## Run the REST API

From the project root:

```bash
Rscript -e "source('renv/activate.R'); source('scripts/run_api.R')"
```

The API loads the saved model artifact and exposes the completion-risk prediction endpoint through Plumber.

## Run the Shiny Application

```bash
Rscript -e "source('renv/activate.R'); source('scripts/run_shiny.R')"
```

The application supports:

* **Single Learner** prediction;
* **Batch CSV** prediction;
* input validation;
* separation of invalid records;
* learner risk ranking;
* capacity-based retention prioritization.

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

```r
testthat::test_dir("tests")
```

The tests cover key inference behavior, including:

* prediction output structure;
* valid probability ranges;
* required feature validation;
* single and batch prediction behavior;
* API-related integration checks.

The test suite is also executed automatically through **GitHub Actions**.

## Reproducibility

The repository uses `renv` to keep the R package environment reproducible.

A clean setup should therefore require only:

```r
install.packages("renv")
renv::restore()
```

followed by either the API or Shiny startup command.

## Documentation

For the detailed analytical workflow, modeling decisions, feature engineering, validation logic, and deployment design, see:

[`PROJECT_DOCUMENTATION.md`](PROJECT_DOCUMENTATION.md)
