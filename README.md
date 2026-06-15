# Stepik EdTech Analytics: Activation Gap, Learner Segmentation and Completion Risk Modeling

![R](https://img.shields.io/badge/R-4.2+-blue)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange)
![Machine Learning](https://img.shields.io/badge/ML-Random%20Forest%20%7C%20XGBoost-green)
![Status](https://img.shields.io/badge/Status-Portfolio%20Project-purple)
![License](https://img.shields.io/badge/License-MIT-green)

## Project Overview

This project analyzes user behavior in the Stepik course **Interactive Data Analysis in R** and develops an end-to-end analytical workflow for understanding learner drop-off, behavioral segments, and early completion risk.

The project is organized into three connected stages:

1. **Product Analysis and EDA**  
   Identification of the early **Activation Gap** and key drop-off points in the learning funnel.

2. **Behavioral Segmentation**  
   K-means clustering of resolved learners into actionable behavioral groups.

3. **Completion Risk Modeling**  
   Supervised machine learning models that estimate `P(Completed)` from the first 10 days of user behavior and convert it into a business risk score:

   `Risk_Not_Completed = 1 - P(Completed)`

The final modeling workflow is designed as a **progress-aware early monitoring system**, supported by ablation and engagement-only robustness checks.

---

## Business Problem

Many users disengage before moving from passive content consumption into meaningful practical activity. This early drop-off is treated as an **Activation Gap**.

The main business questions are:

- Where do users disengage during the early course journey?
- Which behavioral patterns distinguish passive users, steady learners, and high-intensity learners?
- Can early 10-day behavior help identify users who are unlikely to complete the course?
- Which signals are most predictive: activity volume, practical activation, progress, productivity, or recency?
- How much of the prediction signal depends on progress-related target proxies?
- Can engagement-only behavior still provide useful signal after removing direct progress variables?

---

## Data Sources

The project uses two Stepik datasets:

### `event_data_train.csv`

Event-level user interaction logs.

Main variables:

| Variable | Description |
|---|---|
| `step_id` | Anonymized step identifier |
| `user_id` | Anonymized user identifier |
| `timestamp` | Event time in Unix timestamp format |
| `action` | User action: `discovered`, `viewed`, `started_attempt`, `passed` |

### `submissions_data_train.csv`

Submission-level data for practical assignments.

Main variables:

| Variable | Description |
|---|---|
| `step_id` | Anonymized step identifier |
| `user_id` | Anonymized user identifier |
| `timestamp` | Submission time in Unix timestamp format |
| `submission_status` | Submission result: `correct` or `wrong` |

---

## Project Structure

```text
stepik-edtech-analytics/
├── data/
│   ├── raw/                         # Raw Stepik datasets
│   └── processed/                   # Processed modeling and segmentation datasets
│
├── notebooks/
│   ├── 01_product_analysis_eda.ipynb
│   ├── 02_behavioral_segmentation.ipynb
│   └── 03_completion_risk_modeling.ipynb
│
├── images/                          # README visualizations and exported plots
│
├── requirements.R                   # Required R packages
├── README.md
└── .gitignore
```

---

## Analytical Workflow

## Part 1: Product Analysis and Activation Gap Diagnosis

The first stage focuses on product analytics and early learner behavior.

Main steps:

- load and audit raw event and submission logs;
- convert timestamps and reconstruct user timelines;
- analyze activity, practical starts, submissions, and passed steps;
- identify funnel drop-off points;
- define resolved learner trajectories;
- apply P99-based filtering for extreme high-activity users;
- build user-level behavioral features.

Key finding:

The largest drop-off happens before meaningful practical engagement. Many users view or discover content but do not progress to practical attempts or submissions. This is summarized as the **Activation Gap**.

---

## Part 2: Behavioral Segmentation

The second stage uses clustering to segment resolved learners by behavioral patterns.

Main steps:

- create user-level behavioral features;
- normalize features for clustering;
- compare possible values of `K`;
- select the final segmentation using K-means;
- analyze completion outcomes after clustering.

Final segmentation:

| Segment | Description |
|---|---|
| Passive Users | Minimal engagement and almost no practical progress |
| Steady Learners | Sustained participation with moderate practical activity |
| Burst Learners | Concentrated high-intensity activity and higher per-day productivity |

The segmentation supports business interpretation but is not used directly as an input to the supervised prediction models.

---

## Part 3: Completion Risk Modeling

The third stage builds supervised models using behavioral signals from the first 10 days of user activity.

### Prediction Target

Course completion is defined by the platform rule:

| Class | Definition |
|---|---|
| `Completed` | User reaches at least 75 points |
| `Not_Completed` | User remains below 75 points |

`Completed` is treated as the positive class because it is rare and more informative.

The final model output is:

`P(Completed)`

For business prioritization, this is inverted into:

`Risk_Not_Completed = 1 - P(Completed)`

Users with the lowest predicted completion probability are treated as highest-risk candidates for retention intervention.

---

## Modeling Settings

The project evaluates two complementary prediction settings.

### 1. Progress-Aware Prediction Setting

This is the primary practical modeling setting.

It uses early 10-day features including:

- activity volume;
- practical starts;
- submissions;
- passed steps;
- productivity;
- recency;
- engineered activation and intensity features.

Because completion is score-based, progress-, pass-, score-, submission-, and success-related variables may act as target proxies. Therefore, this setting is interpreted as **early progress monitoring**, not as a fully leakage-free future-prediction setup.

### 2. Leakage-Reduced Engagement-Only Robustness Check

This secondary setting removes direct score/progress proxy features.

It keeps general engagement, recency, and practical-start behavior to test whether meaningful signal remains after reducing target-proxy risk.

This setting is not used to replace the main models. It is used as a robustness check.

---

## Feature Engineering

The engineered progress-aware feature set adds interpretable signals linked to the Activation Gap.

| Feature group | Example features | Purpose |
|---|---|---|
| Activation flags | `has_started_practical`, `has_submitted`, `has_passed_practical`, `is_recently_active` | Capture whether users crossed key activation thresholds |
| Ratio / intensity features | `started_practical_per_viewed_step`, `practical_pass_rate`, `passed_per_viewed_step` | Measure relative progress and practical engagement intensity |
| Practice intensity | `submissions_per_active_day`, `practical_starts_per_active_day` | Distinguish passive activity from active practice |

Ratio features based on viewed steps are interpreted as behavioral intensity indicators rather than strict conversion rates, because viewed, started, and passed events are not always perfectly nested in the platform logs.

---

## Models

The supervised modeling workflow compares:

- Random Forest;
- XGBoost.

Class imbalance strategies include:

- baseline training;
- class weighting;
- 1:3 resampling;
- 1:1 resampling.

The validation set is used for:

- feature-set comparison;
- model-family comparison;
- targeted hyperparameter tuning;
- threshold selection;
- final validation-stage model selection.

The test set is reserved for final holdout evaluation only.

---

## Evaluation Metrics

Because the target is severely imbalanced, accuracy is not used as the main metric.

The project focuses on:

| Metric | Purpose |
|---|---|
| `PR-AUC` | Main ranking metric under rare positive class |
| `ROC-AUC` | General ranking and class separation |
| `Recall` | Share of actual `Completed` users detected |
| `Precision` | Correctness of predicted `Completed` users |
| `F1` | Balanced precision-recall score |
| `F2` | Recall-weighted threshold metric |
| `FPR` | False-positive rate |
| `FNR` | False-negative rate |
| `Brier Score` | Probability calibration diagnostic |

Threshold-based metrics are calculated for the rare `Completed` class. Business intervention targeting later uses the inverted risk score.

---

## Final Selected Models

Two progress-aware models are selected for different operational roles:

| Model | Role |
|---|---|
| `XGB_Baseline_Tuned` | Primary ranking-oriented model for estimating `P(Completed)` |
| `RF_Resampled_1_1_Tuned` | Threshold-oriented challenger for completion-signal detection |

`XGB_Baseline_Tuned` is used as the primary model for probability-based ranking.

`RF_Resampled_1_1_Tuned` is retained as an alternative Random Forest benchmark and threshold-oriented challenger.

---

## Risk Prioritization Strategy

The final score is translated into a practical retention prioritization signal:

`Risk_Not_Completed = 1 - P(Completed)`

Suggested intervention tiers:

| Risk tier | Suggested segment | Recommended intervention |
|---|---|---|
| Critical risk | Top 5% highest risk | Immediate nudge, first-task prompt, simplified entry path |
| High risk | Top 10% highest risk | Onboarding support, first-submission guidance, skeleton code |
| Medium-high risk | Top 20% highest risk | Progress feedback, next-step recommendation, task hints |
| Broad risk pool | Top 30% highest risk | Low-cost automated campaign, reactivation reminder |
| Lower risk | Remaining users | Minimal intervention or achievement-oriented motivation |

The model is used as a prioritization tool, not as a causal estimate of intervention effectiveness.

---

## Key Findings

- Early 10-day behavior contains strong signal for eventual course completion.
- Practical activation and early progress are among the strongest predictors.
- Recency is also important: users who remain active closer to the end of the 10-day window are more likely to complete.
- Progress-aware models provide the strongest operational performance.
- `n_passed_practical` is the dominant progress-related predictor.
- Removing `n_passed_practical` weakens performance, but meaningful signal remains.
- Engagement-only models perform weaker, but still retain useful predictive signal.
- Model probabilities are not perfectly calibrated and should be interpreted mainly as ranking scores.
- The results support the Activation Gap interpretation: users who do not move from passive viewing into practical engagement are at higher non-completion risk.

---

## Robustness Checks

### Dominant Feature Ablation

The strongest progress-related feature, `n_passed_practical`, is removed and the selected model families are retrained.

Purpose:

- test whether the model depends mainly on one dominant progress variable;
- assess whether broader activity, productivity, recency, and practical-engagement signals remain useful.

Result:

Removing `n_passed_practical` reduces performance, but does not eliminate predictive signal. The models redistribute importance to related progress-aware predictors such as `n_passed_all`, `n_started_practical`, activity volume, productivity, and recency.

### Engagement-Only Robustness Check

Direct score/progress proxy features are removed.

Result:

Performance decreases, but engagement-only models still retain meaningful signal. This suggests that early engagement, recency, and practical-start behavior carry predictive value beyond direct score accumulation.

---

## Calibration

Calibration is evaluated using:

- probability bins;
- Brier Score;
- calibration plot.

Findings:

- Neither selected progress-aware model is perfectly calibrated.
- `XGB_Baseline_Tuned` is better calibrated than the Random Forest challenger.
- `RF_Resampled_1_1_Tuned` shows stronger overconfidence, especially in higher probability bins.
- Model outputs should be interpreted mainly as ranking scores rather than exact literal probabilities.

---

## Limitations

- The main models are progress-aware and include predictors related to early score accumulation.
- Some users already reached the completion threshold within the first 10-day observation window.
- The ablation check reduces target-proxy concern only partly.
- Engagement-only models are weaker and are used only as robustness checks.
- Validation data is used for several development decisions, so validation metrics are not unbiased generalization estimates.
- Test-set results are used only after model and threshold selection.
- The model is trained on historical data from one course period.
- Changes in course structure, scoring rules, or learner population may require revalidation.
- The model does not estimate intervention effectiveness.
- A/B testing is required to evaluate whether retention interventions improve completion outcomes.

---

## Business Impact

The project provides a framework for moving from retrospective churn analysis to proactive retention prioritization.

Potential use cases:

- identify users with weak early completion signal;
- assign users to risk-based intervention tiers;
- trigger automated nudges or onboarding support;
- reduce unnecessary interventions for users with strong completion signal;
- support future A/B testing of retention actions.

The final output should be used as a decision-support layer, not as a fully automated intervention system.

---

## Tech Stack

| Category | Tools |
|---|---|
| Language | R |
| Data processing | `data.table`, `dplyr`, `tidyr` |
| Visualization | `ggplot2`, `corrplot` |
| Modeling | `randomForest`, `xgboost`, `caret` |
| Evaluation | `pROC`, `MLmetrics` |
| Environment | Jupyter Notebook / R Kernel |

---

## How to Run

### 1. Clone the repository

```bash
git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git
cd stepik-edtech-analytics
```

### 2. Install R dependencies

Open R or RStudio and run:

```r
install.packages("pacman")

pacman::p_load(
  data.table,
  dplyr,
  tidyr,
  ggplot2,
  caret,
  randomForest,
  xgboost,
  pROC,
  MLmetrics,
  corrplot
)
```

Alternatively, run:

```r
source("requirements.R")
```

### 3. Add raw data

Place the raw Stepik datasets into:

```text
data/raw/
```

Expected files:

```text
event_data_train.csv
submissions_data_train.csv
```

### 4. Run notebooks in order

```text
01_product_analysis_eda.ipynb
02_behavioral_segmentation.ipynb
03_completion_risk_modeling.ipynb
```

The notebooks produce processed datasets, feature tables, model results, and final diagnostics.

---

## Repository Outputs

The workflow creates:

- cleaned and processed user-level datasets;
- segmentation tables;
- 10-day prediction feature datasets;
- trained model objects;
- validation and test result tables;
- risk prioritization tables;
- calibration diagnostics;
- feature-importance outputs;
- ablation and robustness-check results.

---

## Final Conclusion

This project shows that early learner behavior contains meaningful signal for eventual course completion. The strongest signals are related to practical activation, early progress, productivity, and recency.

The final models are best interpreted as **progress-aware completion risk models**. They are useful for early monitoring and retention prioritization, but not as fully leakage-free future-prediction models or causal explanations.

The recommended operational model is `XGB_Baseline_Tuned` for ranking users by `P(Completed)` and deriving `Risk_Not_Completed`. `RF_Resampled_1_1_Tuned` can be used as a threshold-oriented challenger.

The engagement-only robustness check supports the broader conclusion that early user behavior contains predictive value beyond direct score accumulation.

---

## License

This project is provided for educational and portfolio purposes.
