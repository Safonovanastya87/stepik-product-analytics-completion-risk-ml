# Stepik EdTech Analytics and Learner Non-Completion Risk

An end-to-end EdTech analytics and machine learning project for identifying learners with elevated course non-completion risk during the **first 10 course days**.

The project combines:

- product and learner behavior analysis;
- behavioral segmentation;
- XGBoost completion-risk modeling;
- reusable model inference;
- Plumber REST API;
- Shiny application;
- single-learner and batch prediction;
- capacity-based retention prioritization;
- automated validation and testing.

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

The project consists of two running application components:

```text
PowerShell Terminal 1
└── Plumber API
    └── http://127.0.0.1:8001

PowerShell Terminal 2
└── Shiny application
    └── http://127.0.0.1:3838
```

Before starting them for the first time, restore the R package environment using an **R Console**.

The instructions below are written for **Windows + VS Code**.

---

## 1. Clone the Repository

### Where to run this

Open **VS Code**.

Then open:

```text
Terminal
→ New Terminal
```

Make sure the terminal is **PowerShell**.

The PowerShell prompt normally starts with:

```text
PS C:\...
```

Run:

```powershell
git clone https://github.com/Safonovanastya87/stepik-product-analytics-completion-risk-ml.git
```

Then move into the project folder:

```powershell
cd stepik-product-analytics-completion-risk-ml
```

Check that you are in the correct directory:

```powershell
Get-Location
```

The path should end with:

```text
stepik-product-analytics-completion-risk-ml
```

You can also check that the project lockfile exists:

```powershell
Test-Path .\renv.lock
```

Expected result:

```text
True
```

---

## 2. Restore the R Environment

### Important

The commands in this step are **R commands**.

Do **not** enter them directly into PowerShell.

Open an **R Console** from the project directory.

The R prompt looks like:

```text
>
```

First verify the current working directory:

```r
getwd()
```

It should point to:

```text
.../stepik-product-analytics-completion-risk-ml
```

Check that R can see the lockfile:

```r
file.exists("renv.lock")
```

Expected result:

```text
TRUE
```

The project uses `renv` for reproducible dependency management.

If `renv` is not installed on the computer, run in the **R Console**:

```r
install.packages("renv")
```

Then restore the project environment:

```r
renv::restore()
```

Wait until the restore process has completed.

The project was developed with **R 4.6.1**.

After restoration, check the environment:

```r
renv::status()
```

You can also verify that the main model package is available:

```r
packageVersion("xgboost")
```

If a version number is returned, `xgboost` is available in the active project environment.

At this point the initial dependency setup is complete.

---

## 3. Start the Plumber API

The API must remain running while the Shiny application is used.

### Where to run this

Return to **VS Code**.

Open:

```text
Terminal
→ New Terminal
```

This is:

```text
PowerShell Terminal 1
```

Make sure it starts with:

```text
PS ...
```

and make sure it is in the project root:

```powershell
Get-Location
```

If necessary, navigate to the project:

```powershell
cd "C:\path\to\stepik-product-analytics-completion-risk-ml"
```

### Check whether `Rscript` is available

Run in **PowerShell Terminal 1**:

```powershell
Rscript --version
```

If this displays the R version, start the API with:

```powershell
Rscript -e "source('renv/activate.R'); source('scripts/run_api.R')"
```

### If PowerShell says that `Rscript` is not recognized

Specify the full path to `Rscript.exe`.

For example:

```powershell
$Rscript = "D:\R-4.6.1\bin\x64\Rscript.exe"
```

Then start the API:

```powershell
& $Rscript -e "source('renv/activate.R'); source('scripts/run_api.R')"
```

The exact path to R may be different on another computer.

The API runs at:

```text
http://127.0.0.1:8001
```

Health endpoint:

```text
http://127.0.0.1:8001/health
```

Open this address in a **web browser** to verify that the API is running.

### Important

Leave **PowerShell Terminal 1 open**.

Do not stop the API before starting Shiny.

---

## 4. Start the Shiny Application

The API from the previous step must still be running.

### Where to run this

In VS Code open another terminal:

```text
Terminal
→ New Terminal
```

This is:

```text
PowerShell Terminal 2
```

You should now have:

```text
Terminal 1 → Plumber API
Terminal 2 → Shiny
```

Check that Terminal 2 is also in the project root:

```powershell
Get-Location
```

If necessary:

```powershell
cd "C:\path\to\stepik-product-analytics-completion-risk-ml"
```

### If `Rscript` is available through PATH

Run in **PowerShell Terminal 2**:

```powershell
Rscript -e "source('renv/activate.R'); shiny::runApp('shiny', host = '127.0.0.1', port = 3838, launch.browser = TRUE)"
```

### If an explicit R path is required

Define it again in **Terminal 2**:

```powershell
$Rscript = "D:\R-4.6.1\bin\x64\Rscript.exe"
```

Then run:

```powershell
& $Rscript -e "source('renv/activate.R'); shiny::runApp('shiny', host = '127.0.0.1', port = 3838, launch.browser = TRUE)"
```

The application should open automatically in the default browser.

If it does not, open:

```text
http://127.0.0.1:3838
```

### Keep both terminals running

While using the application, the setup should look like this:

```text
PowerShell Terminal 1
└── Plumber API
    └── http://127.0.0.1:8001

PowerShell Terminal 2
└── Shiny
    └── http://127.0.0.1:3838

Browser
└── Shiny user interface
```

The application runtime flow is:

```text
Browser
   ↓
Shiny application
   ↓
Plumber REST API
   ↓
Reusable inference
   ↓
XGBoost model
```

---

## 5. Stop the Application

When finished, stop the two processes separately.

In **PowerShell Terminal 2**, where Shiny is running:

```text
Ctrl + C
```

Then in **PowerShell Terminal 1**, where the API is running:

```text
Ctrl + C
```

---

## Command Location Summary

| Command / Task | Where to run it |
|---|---|
| `git clone ...` | PowerShell |
| `cd ...` | PowerShell |
| `Get-Location` | PowerShell |
| `Rscript --version` | PowerShell |
| `$Rscript = "..."` | PowerShell |
| `install.packages("renv")` | R Console |
| `renv::restore()` | R Console |
| `renv::status()` | R Console |
| `packageVersion("xgboost")` | R Console |
| Start Plumber API | PowerShell Terminal 1 |
| Start Shiny | PowerShell Terminal 2 |
| Open `/health` | Web browser |
| Use the Shiny application | Web browser |

---

# How to Try It

## Single Learner

After both the API and Shiny application are running:

1. open `http://127.0.0.1:3838` in the browser;
2. open the **Single Learner** tab;
3. enter learner activity for the first 10 course days;
4. click **Predict completion risk**;
5. review the estimated non-completion probability.

No dataset is required for this workflow.

---

## Batch CSV

To quickly test batch scoring, a demo dataset can be generated.

### Where to run this

Open a **new PowerShell terminal** in the project root.

If `Rscript` is available through PATH:

```powershell
Rscript -e "source('renv/activate.R'); source('scripts/generate_demo_batch.R')"
```

If an explicit path to R is required:

```powershell
$Rscript = "D:\R-4.6.1\bin\x64\Rscript.exe"
```

then:

```powershell
& $Rscript -e "source('renv/activate.R'); source('scripts/generate_demo_batch.R')"
```

This creates:

```text
data/demo_batch_learners.csv
```

Then:

1. open the Shiny application;
2. open **Batch CSV**;
3. upload `data/demo_batch_learners.csv`;
4. choose how many learners can be prioritized;
5. run the prediction;
6. review the ranked retention queue.

A second demo file containing intentionally invalid rows can be generated from **PowerShell** with:

```powershell
Rscript -e "source('renv/activate.R'); source('scripts/generate_demo_batch_with_errors.R')"
```

or, when using an explicit R path:

```powershell
& $Rscript -e "source('renv/activate.R'); source('scripts/generate_demo_batch_with_errors.R')"
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

- The largest learner drop-off occurs before meaningful practical engagement.
- Practical activation is strongly associated with eventual course completion.
- Learners show distinct behavioral engagement patterns.
- Activity during the first 10 course days contains useful information for early risk estimation.
- XGBoost provides the final operational prediction model.
- Retention priority is based on ranking predicted non-completion probability rather than an arbitrary business risk threshold.

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

- input validation;
- model inference;
- retention queue ranking;
- batch scoring;
- API integration.

## Run the complete test suite

### Where to run this

Open a **PowerShell terminal** in the project root.

If `Rscript` is available through PATH:

```powershell
Rscript -e "source('renv/activate.R'); testthat::test_dir('tests/testthat', reporter='summary')"
```

If `Rscript` is not available through PATH:

```powershell
$Rscript = "D:\R-4.6.1\bin\x64\Rscript.exe"
```

then:

```powershell
& $Rscript -e "source('renv/activate.R'); testthat::test_dir('tests/testthat', reporter='summary')"
```

The test suite should complete without failed tests.

Tests are also executed through GitHub Actions.

---

# Jupyter Notebooks

The analytical notebooks are located in:

```text
notebooks/
├── 01_product_analysis_activation_gap.ipynb
├── 02_behavioral_segmentation.ipynb
└── 03_completion_risk_modeling.ipynb
```

Open these files directly in **VS Code or Jupyter** and select an **R kernel**.

R code such as:

```r
library(data.table)
library(dplyr)
library(xgboost)
```

must be executed inside:

```text
Jupyter R notebook cell
```

or:

```text
R Console
```

and not directly in PowerShell.

If a notebook on a newly cloned computer reports that a package such as `xgboost` is missing, return to an **R Console** in the project root and run:

```r
renv::status()
renv::restore()
```

Then restart the Jupyter R kernel.

---

# Documentation

More detailed analytical and technical documentation is available here:

- [Full Project Documentation](docs/PROJECT_DOCUMENTATION.md)
- [Modeling Notebook](notebooks/03_completion_risk_modeling.ipynb)
- [Product Analysis](notebooks/01_product_analysis_activation_gap.ipynb)
- [Behavioral Segmentation](notebooks/02_behavioral_segmentation.ipynb)

The full project documentation contains detailed information about the analytical methodology, model development, validation, API design, inference pipeline, application behavior, and project implementation.

---

# Tech Stack

**R · XGBoost · Random Forest · K-Means · Shiny · Plumber · testthat · renv · GitHub Actions**

---

## Limitations

The model was developed using data from one Stepik course and should not be assumed to generalize directly to other courses or learning platforms.

Predictions are intended to support human decision-making rather than replace it.
