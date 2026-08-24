Stepik Product Analytics & Completion Risk ML

End-to-end data science project for early detection of course non-completion risk using learner activity data from Stepik.

The project combines product analytics, behavioral segmentation, machine learning, reusable inference, REST API deployment, an interactive Shiny application, automated testing, and reproducible R workflows.

Project Goal

The main objective is to identify learners with an elevated risk of not completing a course based on their behavior during the first 10 course days.

Instead of using an arbitrary operational risk cutoff, predicted non-completion probabilities are used to rank learners. A retention team can then prioritize the Top N learners according to the intervention capacity available.

Early learner behavior
        ↓
Completion-risk model
        ↓
Non-completion probability
        ↓
Risk ranking
        ↓
Top-N retention queue

Quick Start

The application consists of two local processes:

Plumber REST API
        +
Shiny frontend

Both must be running at the same time.

1. Prerequisites

Install:

Git

R 4.6.1 or a compatible recent R version

Rtools, only if Windows needs to compile packages from source

The project uses renv to restore the required R package versions.

2. Clone the Repository

Open PowerShell, Terminal, Git Bash, or another shell:

git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git
cd stepik-product-analytics-completion-risk-ml

All commands below assume that the current working directory is the project root.

3. Restore the R Environment

Choose either the R console or PowerShell.

Option A — R Console

Open R in the project root.

First, install renv:

install.packages("renv")

After the installation has completed, run:

renv::restore()

If renv is already installed, skip the installation step and run only:

renv::restore()

Option B — PowerShell

From the project root:

R -e "install.packages('renv', repos='https://cloud.r-project.org'); renv::restore()"

If PowerShell reports that R is not recognized, either use the R Console option or add the current R installation to the Windows PATH.

After renv::restore() finishes successfully, the application is ready to start.

4. Start the Application

Two consoles are required: one for the API and one for Shiny.

You can run both processes either from R consoles or directly from PowerShell.

Option A — Start from R Consoles

Console 1 — Start the REST API

source("renv/activate.R")
source("scripts/run_api.R")

Keep this console running.

The API is available at:

http://127.0.0.1:8001

Health endpoint:

http://127.0.0.1:8001/health

Plumber API documentation:

http://127.0.0.1:8001/__docs__/

Console 2 — Start Shiny

Open a second R console in the same project root:

source("renv/activate.R")

shiny::runApp(
  "shiny",
  launch.browser = TRUE
)

The application opens in the default browser and connects to the running local API.

Option B — Start directly from PowerShell

Open two PowerShell windows in the project root.

PowerShell 1 — Start the REST API

R -e "source('renv/activate.R'); source('scripts/run_api.R')"

Keep this PowerShell window running.

PowerShell 2 — Start Shiny

R -e "source('renv/activate.R'); shiny::runApp('shiny', launch.browser=TRUE)"

The browser should open automatically.

Do not enter R commands such as source(...), setwd(...), or renv::restore() directly at a normal PS C:\...> prompt. In PowerShell, run them through R -e "...", or start an R console first.

5. Try the Demo Data

Two ready-to-use XLSX files are included:

data/demo_batch_learners.xlsx
data/demo_batch_learners_with_errors.xlsx

Use the first file to test normal batch scoring.

Use the second file to test validation, rejected-row handling, and partial scoring of valid learners.

Project Workflow

The project covers the full data science lifecycle.

1. Product Analytics

learner activity analysis;

activation-gap analysis;

behavioral patterns associated with course completion;

early-course engagement analysis.

2. Behavioral Segmentation

feature engineering from LMS event data;

K-Means clustering;

learner behavior profiles;

interpretation of completion patterns across segments.

3. Completion Risk Modeling

Random Forest;

XGBoost;

cross-validation;

model comparison;

PR-AUC analysis;

F2-score analysis;

threshold diagnostics;

robustness checks;

calibration analysis;

final model selection.

4. Production Inference

reusable prediction functions;

serialized model artifact;

single-learner prediction;

batch prediction;

input validation;

XLSX-based batch processing.

5. Retention Prioritization

ranking by predicted non-completion probability;

Top-N prioritization;

capacity-based retention queue.

6. Deployment and Quality Assurance

Plumber REST API;

interactive Shiny application;

unit tests;

API integration tests;

batch integration tests;

GitHub Actions CI workflow;

reproducible package environment with renv.

Tech Stack

Language

R

Data & Analytics

data.table

dplyr

tidyr

lubridate

ggplot2

corrplot

cluster

mclust

fpc

Machine Learning

caret

randomForest

xgboost

pROC

PRROC

Application & Data Exchange

plumber

Shiny

readxl

writexl

Reproducibility & Testing

renv

testthat

GitHub Actions

Repository Structure

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

Analytical Notebooks

The analytical workflow is documented in three Jupyter notebooks.

notebooks/01_product_analysis_activation_gap.ipynb
notebooks/02_behavioral_segmentation.ipynb
notebooks/03_completion_risk_modeling.ipynb

Notebook 01 — Product Analysis & Activation Gap

Focuses on:

learner activity;

early engagement;

course progression;

practical-task activation;

behavioral patterns associated with eventual completion.

Notebook 02 — Behavioral Segmentation

Focuses on:

learner-level behavioral features;

clustering;

segment interpretation;

differences in completion outcomes across behavioral profiles.

Notebook 03 — Completion Risk Modeling

Focuses on:

construction of the early prediction dataset;

train / validation / holdout separation;

Random Forest and XGBoost modeling;

model comparison;

threshold diagnostics;

robustness checks;

final model evaluation;

operational model artifact creation.

The trained production artifact is saved separately, so the modeling notebook does not need to be rerun for normal inference.

Observation Window

Prediction features describe learner behavior during the first 10 course days.

Examples include:

total passed steps;

total viewed steps;

practical activity;

submissions;

submission correctness;

active days;

recency of activity;

score per active day;

passed steps per active day.

The objective is to use early behavior to estimate eventual course-completion probability before the final outcome is known.

Model Artifact

Production inference uses:

artifacts/completion_risk_artifact.rds

The artifact contains the operational XGBoost model together with the information required for reusable inference, including:

serialized model object;

required feature list;

feature order;

model metadata;

inference settings;

evaluation-related metadata.

This allows predictions to be produced without retraining the model or rerunning the analytical notebooks.

The project also stores broader modeling outputs separately:

models/completion_risk_model_objects.rds
results/completion_risk_result_tables.rds

These files preserve modeling and evaluation objects from the analytical workflow and are separate from the production inference artifact.

Prediction Output

For every valid learner, the inference pipeline returns:

completion_probability
completion_risk

where:

completion_risk = 1 - completion_probability

Example:

completion_probability = 0.28
completion_risk        = 0.72

This corresponds to an estimated:

28% probability of course completion
72% probability of non-completion

The probability is treated as a model-based risk estimate rather than as causal evidence that an intervention will change the learner's outcome.

Capacity-Based Retention Queue

The operational workflow does not depend on an arbitrary fixed intervention threshold.

Instead, learners are:

scored by the model;

sorted by completion_risk from highest to lowest;

assigned a risk_rank;

selected according to available Top-N intervention capacity.

The retention queue contains:

risk_rank
user_id
completion_probability
completion_risk

All valid learners
        ↓
Model scoring
        ↓
Sort by completion_risk
        ↓
Assign risk_rank
        ↓
Select Top N
        ↓
Retention queue

This makes the workflow suitable for scenarios where a retention team can contact only a limited number of learners.

Demo Batch Data

Two ready-to-use XLSX files are included:

data/demo_batch_learners.xlsx
data/demo_batch_learners_with_errors.xlsx

Valid Demo

data/demo_batch_learners.xlsx contains 100 anonymized learner feature records sampled from the finalized holdout test set after model development and final evaluation.

The demo records therefore use the same 10-day feature-engineering pipeline as the trained model.

Original learner identifiers are replaced with neutral demo IDs:

10001 ... 10100

The valid demo dataset is exported at the end of:

notebooks/03_completion_risk_modeling.ipynb

The export takes place only after model development and final holdout evaluation. The demo data are therefore used only for demonstrating inference and batch-scoring workflows and do not influence model selection or tuning.

Demo with Validation Errors

data/demo_batch_learners_with_errors.xlsx is derived from the valid demo dataset.

It intentionally modifies selected rows to demonstrate:

range validation;

cross-field validation;

rejected-row handling;

partial scoring of valid learners;

validation feedback in the Shiny interface.

Regenerate the validation-error demo

R Console

source("renv/activate.R")
source("scripts/generate_demo_batch_with_errors.R")

PowerShell

R -e "source('renv/activate.R'); source('scripts/generate_demo_batch_with_errors.R')"

Batch XLSX Input Format

Each row represents one learner observed during the first 10 course days.

The workbook must contain these columns:

user_id
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

Detailed validation logic is implemented in:

R/validate_prediction_input.R

Validation covers both individual feature ranges and selected logical relationships between fields.

File-Based Batch Scoring

Batch inference can be run directly without the Shiny interface.

The workflow is implemented in:

R/batch_scoring.R
scripts/run_batch_scoring.R

The default script uses:

data/demo_batch_learners.xlsx

and produces:

outputs/completion_risk_predictions.xlsx
outputs/retention_queue.xlsx

Run from the R Console

source("renv/activate.R")
source("scripts/run_batch_scoring.R")

Run from PowerShell

R -e "source('renv/activate.R'); source('scripts/run_batch_scoring.R')"

The script:

loads the reusable inference functions;

reads learner data from XLSX;

validates and scores the learners;

calculates completion and non-completion probabilities;

ranks learners by non-completion risk;

creates the Top-N retention queue;

writes the results to XLSX.

REST API

The model is exposed through a local Plumber REST API.

Implementation:

api/plumber.R

The API provides endpoints for health checking and prediction workflows, including single-learner and batch prediction.

The normal startup procedure is described in Quick Start → Start the Application above.

Shiny Application

The project includes an interactive Shiny frontend connected to the local Plumber API.

Implementation:

shiny/app.R

The application provides two workflows:

Single Learner
Batch XLSX

Single Learner

Allows a learner feature profile to be entered manually.

The application:

validates the input;

sends valid data to the REST API;

displays the estimated non-completion probability.

Batch XLSX

Allows an XLSX file containing multiple learners to be uploaded.

The application:

validates each learner independently;

separates invalid records;

scores valid learners;

ranks them by non-completion probability;

creates a capacity-based Top-N priority queue;

provides XLSX downloads for results.

Application Preview

Single Learner



Batch XLSX



Automated Testing

The project uses testthat.

Tests cover:

prediction input validation;

feature range validation;

cross-field validation;

prediction output structure;

probability consistency;

retention-queue ranking;

Top-N prioritization;

XLSX batch scoring;

REST API integration;

batch API integration.

Run tests from the R Console

source("renv/activate.R")

testthat::test_dir(
  "tests/testthat",
  reporter = "summary"
)

Run tests from PowerShell

R -e "source('renv/activate.R'); testthat::test_dir('tests/testthat', reporter='summary')"

A successful run should complete without failed tests.

Continuous Integration

The repository contains a GitHub Actions workflow for the automated R test suite:

.github/workflows/r-tests.yml

This provides an additional reproducibility and regression-safety check outside the local development environment.

Reproducibility

The project uses renv to preserve the package environment.

Package versions required for analytics, machine learning, testing, REST API deployment, Shiny, and XLSX processing are recorded in:

renv.lock

For a clean installation, follow the setup sequence in Quick Start:

Clone repository
        ↓
Install / open R
        ↓
Install renv
        ↓
Restore renv environment
        ↓
Start API
        ↓
Start Shiny

The trained production model is stored separately from the analytical notebooks, allowing inference without retraining.

Key Findings

The analytical workflow indicates that:

the largest learner drop-off occurs before practical engagement begins;

practical activation is strongly associated with eventual course completion;

learner behavior can be grouped into distinct behavioral segments;

behavior during the first 10 course days contains useful information for early completion-risk prediction;

XGBoost provides the strongest overall predictive performance among the evaluated approaches;

the selected operational model provides a practical balance between predictive performance and implementation simplicity;

engagement-only features remain informative even when direct progress-related variables are removed;

completion-risk predictions can be operationalized through capacity-based learner prioritization.

These findings describe predictive associations and should not be interpreted as causal evidence that a specific retention intervention will improve completion.

Documentation

Detailed analytical and technical documentation is available in:

docs/PROJECT_DOCUMENTATION.md

It covers:

analytical methodology;

activation-gap analysis;

behavioral segmentation;

feature engineering;

model development;

model evaluation;

robustness analysis;

inference architecture;

API design;

Shiny workflow;

retention prioritization;

testing;

limitations;

business interpretation.

License

This project is licensed under the MIT License.