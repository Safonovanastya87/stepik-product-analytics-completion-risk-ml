# Stepik EdTech Analytics and Learner Non-Completion Risk

![R](https://img.shields.io/badge/R-4.6.1-blue)
![Machine Learning](https://img.shields.io/badge/ML-XGBoost-green)
![Shiny](https://img.shields.io/badge/UI-Shiny-blue)
![Plumber](https://img.shields.io/badge/API-Plumber-lightgrey)
![Testing](https://img.shields.io/badge/Testing-testthat-blueviolet)
![Status](https://img.shields.io/badge/Status-Portfolio%20Project-purple)

An end-to-end EdTech analytics and machine learning project for identifying learners with elevated course non-completion risk during the **first 10 course days**.

The project combines:

* product and learner behavior analysis;
* behavioral segmentation;
* XGBoost completion-risk modeling;
* reusable model inference;
* Plumber REST API;
* Shiny application;
* single-learner and batch prediction;
* capacity-based retention prioritization;
* automated validation and testing.

## Application

The final Shiny application supports two workflows.

### Single Learner

Enter learner activity manually and estimate the learner's probability of course non-completion.

![Single Learner prediction](docs/images/shiny_single.png)

### Batch CSV

Upload multiple learners, validate the data, score valid learners and create a **Top N retention priority queue**.

Invalid rows are separated instead of blocking the complete batch.

![Batch learner prioritization](docs/images/shiny_batch.png)

---

# Quick Start

## 1. Clone the repository

```bash
git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git
cd stepik-product-analytics-completion-risk-ml
```

## 2. Restore the R environment

The project uses `renv`.

```r
install.packages("renv")
renv::restore()
```

The project was developed with **R 4.6.1**.

## 3. Start the API

From the project root:

```bash
Rscript -e "source('renv/activate.R'); source('scripts/run_api.R')"
```

The API runs at:

```text
http://127.0.0.1:8001
```

Health endpoint:

```text
http://127.0.0.1:8001/health
```

## 4. Start Shiny

Open a second terminal in the project root:

```bash
Rscript -e "source('renv/activate.R'); shiny::runApp('shiny', host = '127.0.0.1', port = 3838, launch.browser = TRUE)"
```

The application opens at:

```text
http://127.0.0.1:3838
```

---

# How to Try It

## Single Learner

1. Open the **Single Learner** tab.
2. Enter learner activity for the first 10 course days.
3. Click **Predict completion risk**.
4. Review the estimated non-completion probability.

No dataset is required for this workflow.

## Batch CSV

To quickly test batch scoring, generate demo data:

```bash
Rscript scripts/generate_demo_batch.R
```

This creates:

```text
data/demo_batch_learners.csv
```

Then:

1. open **Batch CSV**;
2. upload `data/demo_batch_learners.csv`;
3. choose how many learners can be prioritized;
4. run the prediction;
5. review the ranked retention queue.

A second demo file containing intentionally invalid rows can be generated with:

```bash
Rscript scripts/generate_demo_batch_with_errors.R
```

This demonstrates row-level validation and rejected-row handling.

---

# How It Works

```text
Learner activity — first 10 days
              ↓
       Input validation
              ↓
         XGBoost model
              ↓
 Non-completion probability
              ↓
      Rank learners by risk
              ↓
 Top N according to retention capacity
```

The system provides **decision support** rather than automatically deciding which learners should receive an intervention.

---

# Project Workflow

```text
Product Analytics
       ↓
Behavioral Segmentation
       ↓
Completion-Risk Modeling
       ↓
Reusable Model Inference
       ↓
Plumber REST API
       ↓
Shiny Application
       ↓
Retention Prioritization
```

## Key Findings

* The largest learner drop-off occurs before meaningful practical engagement.
* Practical activation is strongly associated with eventual course completion.
* Learners show distinct behavioral engagement patterns.
* Activity during the first 10 course days contains useful information for early risk estimation.
* XGBoost provides the final operational prediction model.
* Retention priority is based on ranking predicted non-completion probability rather than an arbitrary business risk threshold.

---

# Architecture

```text
stepik-product-analytics-completion-risk-ml/
├── api/          # Plumber REST API
├── artifacts/    # Serialized trained model
├── data/         # Demo and processed data
├── notebooks/    # Analytics and model development
├── R/            # Reusable inference and validation functions
├── scripts/      # API and demo-data utilities
├── shiny/        # Shiny application
├── tests/        # Automated tests
└── docs/         # Detailed documentation and images
```

---

# Testing

The project includes automated tests for:

* input validation;
* model inference;
* retention queue ranking;
* batch scoring;
* API integration.

Run the complete test suite with:

```bash
Rscript -e "source('renv/activate.R'); testthat::test_dir('tests/testthat', reporter='summary')"
```

Tests are also executed through GitHub Actions.

---

# Documentation

More detailed technical documentation is available here:

* [Full Project Documentation](docs/PROJECT_DOCUMENTATION.md)
* [Modeling Notebook](notebooks/03_completion_risk_modeling.ipynb)
* [Product Analysis](notebooks/01_product_analysis_activation_gap.ipynb)
* [Behavioral Segmentation](notebooks/02_behavioral_segmentation.ipynb)

---

# Tech Stack

**R · XGBoost · Random Forest · K-Means · Shiny · Plumber · testthat · renv · GitHub Actions**

---

## Limitations

The model was developed using data from one Stepik course and should not be assumed to generalize directly to other courses or learning platforms.

Predictions are intended to support human decision-making rather than replace it.
