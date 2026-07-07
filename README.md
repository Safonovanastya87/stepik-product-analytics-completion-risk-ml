# Stepik EdTech Analytics: Activation Gap, Learner Segmentation and Completion Risk Modeling

![R](https://img.shields.io/badge/R-4.2+-blue)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange)
![Machine Learning](https://img.shields.io/badge/ML-Random%20Forest-green)
![Product Analytics](https://img.shields.io/badge/Product%20Analytics-Retention%20%7C%20Segmentation-purple)
![Status](https://img.shields.io/badge/Status-Portfolio%20Project-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Project Overview

This project is an end-to-end EdTech analytics case study based on user activity data from the online learning platform **Stepik**.

The analysis combines product analytics, learning analytics, behavioral segmentation, and machine learning to understand how learners engage with an online course, where they disengage, and how early behavioral signals can be used to identify users at risk of non-completion.

The project analyzes learner behavior in the course **Interactive Data Analysis in R** and addresses a central business question:

> Why do learners fail to complete the course, and how early can at-risk users be identified?

---

## Business Problem

Online learning platforms often experience substantial learner drop-off before course completion.

The project investigates:

* where learners disengage during the course journey;
* which course steps create the strongest friction;
* how engagement patterns differ across learners;
* which users are most likely to complete the course;
* how early at-risk learners can be identified.

The goal is to move from retrospective completion reporting toward proactive learner-retention analytics.

---

## Dataset

The project uses anonymized user activity data from the Stepik learning platform.

Two datasets are analyzed:

* **Event Data** – content views, discoveries, practical starts, and passed assignments.
* **Submission Data** – practical assignment attempts and submission outcomes.

Together, these datasets allow reconstruction of learner journeys, engagement patterns, and completion trajectories.

---

## Analytical Workflow

### Part 1 — Product Analytics & Activation Gap Analysis

The first stage focuses on understanding learner behavior throughout the course.

Key analyses include:

* funnel analysis;
* learning journey reconstruction;
* step-level engagement analysis;
* practical assignment analysis;
* user-level behavioral profiling.

#### Key Finding

The largest learner drop-off occurs before meaningful practical engagement.

Many users consume content passively but never transition into practical assignments. This gap between content consumption and active learning is defined as the **Activation Gap**.

---

### Part 2 — Behavioral Segmentation

The second stage uses K-Means clustering to identify learner archetypes based on engagement and learning behavior.

Final learner segments:

| Segment         | Description                                       |
| --------------- | ------------------------------------------------- |
| Passive Users   | Low engagement and minimal practical activity     |
| Steady Learners | Consistent participation and moderate progress    |
| Burst Learners  | High-intensity engagement and strong productivity |

#### Key Finding

Learners exhibit distinct behavioral patterns, and completion outcomes differ substantially across segments.

---

### Part 3 — Completion Risk Modeling

The final stage develops machine learning models that estimate the probability of course completion using behavioral signals observed during the first 10 days of activity.

Models evaluated:

* Random Forest
* XGBoost

The final output is:

```text
P(Completed)
```

which is transformed into:

```text
Risk_Not_Completed = 1 − P(Completed)
```

to support learner-retention prioritization.

#### Additional Validation

The modeling workflow includes:

* class imbalance handling;
* hyperparameter tuning;
* feature importance analysis;
* dominant-feature ablation;
* engagement-only robustness checks;
* calibration diagnostics.

---

## Key Findings

* The largest learner drop-off occurs before practical engagement begins.
* Practical activation is one of the strongest indicators of eventual course completion.
* Learners can be grouped into distinct behavioral segments with different engagement patterns and completion outcomes.
* Learner behavior during the first 10 days contains meaningful information for early completion-risk prediction.
* The engineered progress-aware XGBoost approach achieves the strongest overall predictive performance.
* XGB_Baseline is retained as the final model because tuning provides only a marginal PR-AUC improvement while producing a slightly less favorable F2–FPR trade-off.
* A validation-set ablation shows that engagement-only features remain informative after direct progress- and submission-related variables are removed.
* Behavioral segmentation, funnel analysis, and predictive modeling can be combined into a unified learner-retention framework.

---

## Business Impact

The project demonstrates how educational-platform data can support proactive and capacity-aware learner-retention strategies.

Potential applications include:

* identifying and ranking learners by completion risk;
* prioritizing limited intervention resources;
* improving onboarding and practical activation;
* targeting re-engagement campaigns;
* providing personalized learner guidance;
* evaluating retention strategies across behavioral segments.

The resulting framework is intended as a decision-support system. It can help retention teams identify priority groups and select appropriate interventions, but it should not be used as a fully automated decision or intervention engine.

---

## Technical Skills Demonstrated

### Product Analytics

* Funnel Analysis
* Learning Journey Analysis
* Activation Gap Diagnosis
* Step-Level Analytics
* Retention Analytics
* User Behavior Analysis

### Machine Learning

* Random Forest
* XGBoost
* K-Means Clustering
* Hyperparameter Tuning
* Feature Engineering
* Feature Importance Analysis
* Class Imbalance Handling
* Model Validation

### Tools

* R
* data.table
* dplyr
* tidyr
* ggplot2
* caret
* randomForest
* xgboost
* pROC
* MLmetrics
* Jupyter Notebook

---

## Project Structure

```text
stepik-product-analytics-completion-risk-ml/
├── notebooks/
│   ├── 01_product_analysis_activation_gap.ipynb
│   ├── 02_behavioral_segmentation.ipynb
│   └── 03_completion_risk_modeling.ipynb
├── .gitignore
├── LICENSE
├── README.md
└── renv.lock
```


---

## Reproducibility Note

This project includes an `renv.lock` file that records the R package versions used during development and validation.
To reproduce the project environment, open the project root directory and run:

>```r
> install.packages("renv")
> renv::restore()
> ```

The project was developed and tested with R 4.6.0 and `xgboost` 3.2.1.1. The exact package environment is recorded in `renv.lock`.

---

## Final Conclusion

This project demonstrates how product analytics, learning analytics, behavioral segmentation, and machine learning can be combined to understand learner behavior and support retention decisions.

The analysis shows that the most critical transition in the learning journey is the move from passive content consumption to active practical engagement. Learners who fail to cross this activation threshold are substantially less likely to complete the course.

By combining Activation Gap analysis, step-level learning analytics, behavioral segmentation, and completion-risk modeling, the project provides a practical framework for supporting learner retention in online education.

---

## License

This project is provided for educational and portfolio purposes.
