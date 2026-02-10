# EdTech Analytics: From the "Activation Gap" to Churn Prediction

![R](https://img.shields.io/badge/R-4.2+-blue) ![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange) ![License](https://img.shields.io/badge/License-MIT-green)

**Author:** Anastasiya Safonova  
**Date:** 2026  

**Description:** End-to-end product analysis of Stepik user behavior using **R**. Identified the **"Activation Gap"**, performed **behavioral clustering (K-Means)** to segment learner archetypes, and developed a **Random Forest** churn prediction system with refined ground-truth labels.

---

## Business Context & Problem Statement

### **Goal**  
To analyze student drop-off patterns in the !["Data Analysis in R"](https://stepik.org/catalog) course and develop a retention strategy. The project leverages **R's statistical power** to transition from diagnostic analytics to predictive modeling.

---

### **Key Challenges**  
- **The Activation Gap**: 40.7% of users abandon the course before their first practical attempt.
- **System Bias**: Platform logs overestimated "active" users, requiring a custom **30-day inactivity rule** to define true churn.
- **Early Friction**: Analysis showed that 84% of churn occurs on basic difficulty steps, suggesting onboarding issues. 

---

### **Tech Stack**  
- **Language:** R 
- **Libraries:** `tidyverse` (dplyr, ggplot2), `lubridate`, `data.table`, `scales`, `formattable`,`here`, `corrplot`, `knitr`, `randomForest`
- **Models:** K-Means (Clustering), Random Forest (Classification) 
- - **Techniques:** Funnel analysis, feature engineering, class imbalance handling, behavioral segmentation.



---

## Dataset Overview

The project uses two primary datasets from Stepik, covering student interactions and assignment submissions:

- [`events_train.csv`](https://stepik.org/media/attachments/course/4852/event_data_train.zip)
  Contains event-level data describing user interactions.

  **Variables:**
  - `step_id` — anonymized step identifier. 
  - `user_id` — anonymized user identifier.  
  - `timestamp` — event time in Unix timestamp format.
  - `action` — type of user action:
    - `discovered` — navigated to a step. 
    - `viewed` — viewed the content.  
    - `started_attempt` — began solving a practical task.  
    - `passed` — successfully completed the step (applies to both theory and tasks). 
---
  
- [`submissions_train.csv`](https://stepik.org/media/attachments/course/4852/submissions_data_train.zip)
  Contains information about solution submissions for practical assignments.

  **Variables:**
  - `step_id` — anonymized step identifier  
  - `user_id` — anonymized user identifier  
  - `timestamp` — submission time in Unix timestamp format  
  - `submission_status` — submission result (`correct` / `wrong`)  

---
## Project Structure
```
Stepik-Product-Analytics-Churn-ML/
├── data/                 # Raw and processed data
│   ├── .gitkeep          # (опционально) позволяет залить пустую папку на GitHub
├── images/               # Visualizations for README (plots, funnels, clusters)
├── notebooks/            # Jupyter Notebooks (or RMarkdown files)
│   ├── 01_Product_Analysis_and_EDA.ipynb
│   └── 02_Clustering_and_Churn_Prediction.ipynb
├── .gitignore            # Files to be ignored by Git (e.g., large .csv files)
├── LICENSE               # MIT License
├── README.md             # Project documentation
└── requirements.R        # Script to install all necessary R packages
```

---

## Evaluation Metrics

Since the target variable is **imbalanced**, the model’s performance is evaluated mainly using:

| Metric       | Description |
|-------------|-------------|
| F1 Score     | Harmonic mean of Precision & Recall; balances false positives and false negatives. |
| Precision    | Proportion of predicted `High` sales that are correct. |
| Recall       | Proportion of actual `High` sales correctly identified. |
| ROC AUC      | Ability to distinguish between `High` and `Low` classes. |

**Note:** Accuracy is shown for reference but can be misleading due to class imbalance.

---

## Modeling Summary

| Model                       | Accuracy | F1  | ROC AUC |
|-----------------------------|---------|-----|---------|
| Baseline (with Sales_Volume) | 1.00    | 1.0 | 1.0     |
| GridSearch (with Sales_Volume)| 1.00   | 1.0 | 1.0     |
| Baseline (without Sales_Volume)| 0.57  | 0.56| 0.50    |
| GridSearch (without Sales_Volume)| 0.69| 0.68| 0.50    |

**Feature Engineering Highlights:**  
- `Year` → `Years_Since_First_Sale`  
- Standard scaling for numeric features  
- One-hot encoding for categorical features  

---

## Key Findings
- The target is **imbalanced**, requiring `class_weight='balanced'`.  
- `Sales_Volume` almost perfectly separates classes → **potential data leakage**.  
- Removing `Sales_Volume`, performance drops (Accuracy ~0.57–0.69, ROC AUC ~0.5).  
- Remaining features alone are insufficient for accurate classification, highlighting the importance of feature selection.

---

##  Mini EDA Visualizations

**Target Distribution**
![Class Distribution](images/sales_class_distribution.png)  

**Sales_Volume vs Sales_Classification (Boxplot)**
![Sales Volume Separation](images/boxplot_class_volum.png)  

*Observation:*  
`Sales_Volume` shows an almost perfect separation between *Low* and *High* sales classes,  
indicating a potential **data leakage** — a finding later confirmed through modeling.

**Top 10 Feature Importances (GridSearchCV Model) with `Sales_Volume`**
![Feature Importance with Sales_Volume](images/feature_importance_with_volume.png)

*Observation:*  
`Sales_Volume` overwhelmingly dominates the model, confirming potential **data leakage**.  
Other features contribute very little to the prediction.


---

## How to Run
1. **Clone the repository to your local machine:**
   ```bash
   git clone https://github.com/Safonovanastya87/bmw-sales-eda-classification.git
   ```
   

2. **Navigate into the project directory:**
      ```bash
   cd bmw-sales-eda-classification
   ```

3. **Install requirements:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Dataset download notice:**

The dataset is downloaded directly inside the notebook, but for the download to work correctly you must have your Kaggle API token set up — place the kaggle.json file in your .kaggle folder inside your user directory (~/.kaggle/ on Linux/Mac or %USERPROFILE%\.kaggle\ on Windows).

5. **Open the Jupyter Notebook:**
    ```bash
    jupyter notebook notebooks/bmw-sales-eda-classification.ipynb
    ```

  
## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.