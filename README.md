# Heart-Evoked Potentials and Hierarchical Gaussian Filtering in Social Learning Under Uncertainty

This repository contains the core codebase and pipelines used in the analyses described in our study on emotion egocentricity bias (EEB), interoception, and learning under uncertainty using the Hierarchical Gaussian Filter (HGF). It includes pre-processing scripts, model configuration files, post-inference feature extraction, and heart rate response analyses.

---

## 📂 Repository Structure

```
/hgf_configs/              → Custom HGF and observation model configuration files
/hgf_models/               → Custom response model files for HGF inference
/data_preprocessing/       → Scripts to pre-process behavioral data for model fitting
/hgf_postprocessing/       → Scripts to extract HGF-derived features for statistical analysis
/heart_analysis/           → Scripts to extract heart-evoked responses aligned to feedback
/example_data/             → Example (or synthetic) data files [optional]
README.md
LICENSE
```

---

## 🧠 Project Overview

This code supports the following analyses:

- Preprocessing online and offline behavioral data for model inversion.
- Bayesian modeling of trial-wise responses using the Tapas toolbox and a custom response model that integrates prior and posterior beliefs.
- Extraction of subject-wise and condition-wise parameters (e.g., learning rates, precision weights, belief trajectories).
- Processing of heart rate recordings to derive evoked cardiac changes aligned to feedback onset.

---

## ⚙️ Requirements

- MATLAB (tested with R2021a and later)
- [TAPAS Toolbox (HGF)](https://www.tnu.ethz.ch/en/software/tapas.html)
- Signal Processing Toolbox
- Optional: EEGLAB for some preprocessed `.mat` files
- Pan-Tompkins QRS detector function (included or linked)

---

## 📌 Key Files and Scripts

### 🔹 `hgf_configs/`
- `tapas_hgf_binary_config.m`: standard 3-level HGF perceptual model
- `tapas_unitsq_sgm_config_w.m`: customized observation model with response weighting

### 🔹 `hgf_models/`
- `tapas_unitsq_sgm_w2.m`: response model combining prior and posterior beliefs
- `tapas_unitsq_sgm_transp_w.m`: transformation function for response model parameters

### 🔹 `data_preprocessing/`
- `demo_pipeline_online.m`: loads and tidies CSV-based behavioral data (online study)
- `demo_pipeline_offline.m` [optional]: for EEGlab `.mat` files (if needed)

### 🔹 `hgf_postprocessing/`
- `extract_hgf_features.m`: extracts subject-level features such as:
  - learning rates and belief precision (per level and condition)
  - response model parameters (e.g., ζ, ω)
  - average posterior beliefs (`μ̂`) and model evidence (`LME`)

### 🔹 `heart_analysis/`
- `extract_hr_evoked_responses.m`: detects R-peaks and extracts heart-evoked intervals
  - Outputs metrics for initial deceleration, final acceleration, and overall IBI response

---

## 🧪 Example Usage

```matlab
% Step 1: Preprocess behavioral data
config = struct;
config.data_dir = 'data/';
df = demo_pipeline_online(config);

% Step 2: Fit HGF model (requires TAPAS)
% e.g., tapas_fitModel(y, u, 'tapas_hgf_binary_config', 'tapas_unitsq_sgm_w2')

% Step 3: Post-process model output
extract_hgf_features;

% Step 4: Run heart-evoked response analysis
extract_hr_evoked_responses;
```

---

## 🔐 Licensing

This project is distributed under the [GNU General Public License v3](https://www.gnu.org/licenses/gpl-3.0.en.html), in line with the TAPAS toolbox. See `LICENSE` for details.

---

## 📄 Citation

If you use this code, please cite the corresponding preprint or publication (link forthcoming).

> Kotsaris, V., [et al.]. (2025). *Interoceptive predictive processing in emotional bias under uncertainty: Evidence from HGF modeling and cardiac feedback.* [Preprint].

---

## 📬 Contact

For questions or collaborations, please contact:  
**Vassilis Kotsaris**  
PhD, University of Kent  
[Your academic email or GitHub profile link]