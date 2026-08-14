# Stepik EdTech Analytics and Learner Non-Completion Risk

![R](https://img.shields.io/badge/R-4.6.1-blue)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange)
![Machine Learning](https://img.shields.io/badge/ML-XGBoost-green)
![Shiny](https://img.shields.io/badge/UI-Shiny-blue)
![Plumber](https://img.shields.io/badge/API-Plumber-lightgrey)
![Testing](https://img.shields.io/badge/Testing-testthat-blueviolet)
![Status](https://img.shields.io/badge/Status-Portfolio%20Project-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Overview

An end-to-end EdTech analytics and machine learning project based on learner activity data from the online learning platform **Stepik**.

The project investigates:

- where learners disengage during the course journey;
- how learner behavior differs across user groups;
- whether non-completion risk can be identified during the **first 10 course days**;
- how learners with the highest predicted risk can be prioritized when retention capacity is limited.

The final solution combines:

- product and behavioral analysis;
- K-Means learner segmentation;
- Random Forest and XGBoost modeling;
- reusable model inference;
- input validation;
- Plumber REST API;
- Shiny application;
- single and batch prediction;
- capacity-based learner prioritization;
- automated unit and integration testing.

The analyzed course is **Interactive Data Analysis in R**.

> **Main business question:**  
> Why do learners fail to complete the course, and how early can learners with elevated non-completion risk be identified and prioritized for retention support?

---

# Application

The final Shiny application supports two workflows.

### Single Learner

Enter learner activity manually and estimate the learner's probability of course non-completion.

![Single Learner prediction](docs/images/shiny_single.png)

### Batch CSV

Upload multiple learners, validate the input, score valid rows and create a **Top N retention priority queue**.

Invalid rows are separated instead of blocking the entire batch.

![Batch learner prioritization](docs/images/shiny_batch.png)


---

# Quick Start

The instructions below assume **Windows + VS Code**.

## Requirements

- Git
- R **4.6.1**
- VS Code or another IDE/terminal
- Internet connection for the initial dependency restore

**Windows:** `Rtools45` may be required if `renv::restore()` needs to build one or more R packages from source. It is not required when compatible package binaries are available.

## 1. Clone the repository

**VS Code Terminal / PowerShell**

```powershell
git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git
cd stepik-product-analytics-completion-risk-ml
```

Open the cloned folder in VS Code if it is not already open.

## 2. Restore the R environment

**R Console**

```r
install.packages("renv")
renv::restore()
```

The project uses `renv.lock` to restore the package versions used by the project.

## 3. Start the API

**VS Code Terminal / PowerShell**

```powershell
Rscript -e "source('renv/activate.R'); source('scripts/run_api.R')"
```

The API runs at:

```text
http://127.0.0.1:8001
```

Health check:

```text
http://127.0.0.1:8001/health
```

Keep this terminal running.

## 4. Start the Shiny application

Open a **second VS Code terminal**:

```powershell
Rscript -e "source('renv/activate.R'); shiny::runApp('shiny', host = '127.0.0.1', port = 3838, launch.browser = TRUE)"
```

The application runs at:

```text
http://127.0.0.1:3838
```

---

# Demo Batch Data

Two ready-to-use CSV files are included in the repository:

```text
data/demo_batch_learners.csv
data/demo_batch_learners_with_errors.csv
```

### `demo_batch_learners.csv`

Valid learner data for testing the normal batch-scoring workflow.

### `demo_batch_learners_with_errors.csv`

Contains controlled invalid rows for testing:

- row-level validation;
- scoring of valid rows when other rows are invalid;
- the **Rejected rows** view;
- validation-error downloads.

To test batch prediction:

1. start the API and Shiny application;
2. open **Batch CSV**;
3. upload one of the demo files;
4. choose **Learners to prioritize**;
5. run the prediction.

The application returns:

- successfully scored learners;
- rejected rows, when present;
- a ranked Top N intervention queue;
- downloadable prediction and validation results.

---

# CSV Input

Each row represents one learner observed during the **first 10 course days**.

Required fields:

| Column | Description |
|---|---|
| `user_id` | Learner identifier |
| `n_passed_all` | Total passed course steps |
| `n_viewed_all` | Total viewed steps |
| `n_started_practical` | Practical steps started |
| `n_passed_practical` | Practical steps passed |
| `n_submissions` | Number of submissions |
| `submission_correct_rate` | Share of correct submissions |
| `active_days` | Active days in the observation window |
| `days_since_last_action` | Days since the last learner action |
| `score_per_active_day` | Score intensity per active day |
| `steps_per_active_day` | Step activity per active day |

Input ranges and cross-field consistency are validated before prediction.

The authoritative validation implementation is:

```text
R/validate_prediction_input.R
```

---

# Project Workflow

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
Capacity-based retention prioritization
```

---

# 1. Product Analytics

The first stage analyzes learner behavior throughout the course using:

- funnel analysis;
- learning journey reconstruction;
- step-level engagement;
- practical-assignment behavior;
- learner-level activity profiles.

### Key Finding

The largest learner drop-off occurs before meaningful practical engagement.

Many learners consume course content but do not transition into active practical work. This transition is treated as an **Activation Gap**.

---

# 2. Behavioral Segmentation

K-Means clustering is used to identify learner groups with different engagement patterns.

| Segment | Description |
|---|---|
| Passive Users | Low engagement and minimal practical activity |
| Steady Learners | Consistent participation and moderate progress |
| Burst Learners | High-intensity engagement and strong productivity |

The segments show clearly different course-completion behavior.

---

# 3. Completion Risk Modeling

The model uses learner behavior from the **first 10 course days**.

Models evaluated:

- Random Forest;
- XGBoost.

The final operational model uses **XGBoost**.

The model estimates:

```text
P(Completed)
```

and derives:

```text
Non-completion risk = 1 - P(Completed)
```

Model development includes:

- feature engineering;
- class-imbalance handling;
- PR-AUC model comparison;
- F2 and false-positive-rate analysis;
- feature importance;
- robustness checks;
- calibration diagnostics;
- holdout validation.

---

# Classification vs. Retention Prioritization

The model produces a continuous probability.

A classification threshold selected during model evaluation is used for technical model classification, but **not as a business intervention threshold**.

Retention prioritization instead follows:

```text
predicted non-completion probability
                ↓
        sort descending
                ↓
             Top N
                ↓
     retention priority queue
```

This answers the operational question:

> Which N learners should be reviewed first if the retention team can support only N interventions?

---

# Model Artifact

The trained model is stored in:

```text
artifacts/completion_risk_artifact.rds
```

It contains the serialized XGBoost model together with the information required for inference.

Because the trained artifact is included in the project, the modeling notebook does **not** need to be rerun to test the API or Shiny application.

---

# REST API

The model is exposed through a local **Plumber REST API**.

Implementation:

```text
api/plumber.R
```

Main endpoints:

| Endpoint | Purpose |
|---|---|
| `GET /health` | Verify that the API and model are available |
| `POST /predict` | Score one learner |
| `POST /predict-batch` | Score multiple learners and build a Top N queue |

The API performs strict input validation.

For CSV uploads, the Shiny application adds row-level preprocessing so valid learners can still be scored when other rows contain validation errors.

---

# Main R Components

```text
R/load_artifact.R
```

Loads and validates the saved model artifact.

```text
R/validate_prediction_input.R
```

Validates feature structure, types, ranges and cross-field consistency.

```text
R/predict_completion_risk.R
```

Runs model inference and calculates completion and non-completion probabilities.

```text
R/build_retention_queue.R
```

Ranks learners by descending predicted non-completion risk and selects Top N.

```text
R/batch_scoring.R
```

Provides reusable batch-scoring functionality.

---

# Automated Testing

The project uses `testthat` for unit and integration testing.

The test suite covers:

- prediction-input validation;
- range and cross-field validation;
- model inference;
- retention-queue ranking;
- Top N behavior;
- batch scoring;
- API integration;
- batch API integration.

Run all tests from the project root:

**VS Code Terminal / PowerShell**

```powershell
Rscript -e "source('renv/activate.R'); testthat::test_dir('tests/testthat', reporter='summary')"
```

Tests are also executed through GitHub Actions.

---

# Reproducing the Analysis and Model

The analytical workflow is implemented in three Jupyter notebooks:

```text
notebooks/
├── 01_product_analysis_activation_gap.ipynb
├── 02_behavioral_segmentation.ipynb
└── 03_completion_risk_modeling.ipynb
```

Open the notebooks in **VS Code or Jupyter** using an **R kernel** and run them in numerical order.

Training datasets are intentionally **not stored in Git**.

The notebooks automatically obtain the required source data and create local:

```text
data/raw/
data/processed/
```

when needed.

These directories contain generated/downloaded data and are excluded from version control.

The demo CSV files used to test the final application are different: they are stored directly in the repository so batch prediction can be tested immediately after cloning.

---

# Project Structure

```text
stepik-product-analytics-completion-risk-ml/
├── .github/
│   └── workflows/
├── api/
│   └── plumber.R
├── artifacts/
│   └── completion_risk_artifact.rds
├── data/
│   ├── demo_batch_learners.csv
│   └── demo_batch_learners_with_errors.csv
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
│   └── run_api.R
├── shiny/
│   └── app.R
├── tests/
│   └── testthat/
├── .gitignore
├── .Rprofile
├── LICENSE
├── README.md
└── renv.lock
```

`data/raw/`, `data/processed/`, generated models and generated results are created locally when required and are not version-controlled.

---

# Reproducibility

The repository contains:

- source code;
- analytical notebooks;
- `renv.lock`;
- the trained model artifact;
- automated tests;
- CI configuration;
- ready-to-use batch demo data.

`renv` restores the R package environment defined by the project lockfile.

For normal application testing, a new user should only need to:

```text
clone repository
      ↓
restore renv environment
      ↓
start API
      ↓
start Shiny
      ↓
test Single Learner or Batch CSV
```

### Windows dependency note

If `renv::restore()` reports that packages need to be built from source, install **Rtools45** and run `renv::restore()` again.

### If `Rscript` is not recognized

Use the full path to the `Rscript.exe` installed with R instead of the `Rscript` command.

---

# Key Findings

- The largest learner drop-off occurs before practical engagement.
- Practical activation is strongly associated with course completion.
- Learners form distinct behavioral groups with different completion outcomes.
- Behavior during the first 10 course days contains useful information for early risk prediction.
- XGBoost provides the strongest overall predictive performance for the final workflow.
- The trained model can be reused independently of the modeling notebook.
- Continuous risk probabilities can be translated into a capacity-aware retention queue without introducing an unsupported fixed business threshold.

---

# Tech Stack

**Analytics & ML**

R, data.table, dplyr, tidyr, ggplot2, caret, randomForest, xgboost, pROC

**Application & Engineering**

Shiny, Plumber, testthat, renv, Git, GitHub Actions, Jupyter

---

# Limitations

- The model is trained on data from one Stepik course.
- Results may not generalize directly to other courses or learning platforms.
- Behavioral features cannot capture factors such as learner motivation or external circumstances.
- The model classification threshold should not be interpreted as a universal intervention threshold.
- Capacity-based ranking identifies who should be reviewed first but does not prove that an intervention will be effective.
- Predictions are intended to support human decisions rather than replace them.

---

# Conclusion

This project demonstrates an end-to-end workflow from **product analytics and learner behavior analysis to a deployable machine learning decision-support application**.

The final system uses early learner behavior to estimate non-completion risk, exposes the trained model through a REST API, supports individual and batch prediction, validates incoming data and converts model probabilities into a capacity-based retention priority queue.