library(lme4)
library(dplyr)
library(effects)
library(tibble)
library(tidyr)
library(lmerTest)

# Load physiological and HGF data
dfmm<-read.csv('dfall.csv') #trial-level data


# mixed-models for HRA and HGF

lmWT <- lmer(HRFinal ~ WT2 + WT3 + (1|id), data = dfmm)
summary(lmWT)

lmMU <- lmer(HRFinal ~ M2 + M3 + (1|id), data = dfmm)
summary(lmMU)


# subject-wise regressions

# Initialize an empty data frame to store results
resultsHR2 <- data.frame(id = character(),
                         intercept = numeric(),
                         slope_WT2 = numeric(),
                         t_value_WT2 = numeric(),
                         p_value_WT2 = numeric(),
                         slope_WT3 = numeric(),
                         t_value_WT3 = numeric(),
                         p_value_WT3 = numeric(),
                         r_squared = numeric(),
                         stringsAsFactors = FALSE)

# Get unique subject IDs
unique_ids <- unique(dfmm$id)

# Loop through each subject
for (subject_id in unique_ids) {
  # Subset the data for the current subject
  subject_data <- dfmm %>% filter(id == subject_id)
  
  # Run the linear regression
  lm_model <- lm(HRFinal ~ WT2 + WT3, data = subject_data)
  
  # Extract coefficients and R-squared value
  intercept <- coef(lm_model)[1]
  slope_WT2 <- coef(lm_model)[2]
  slope_WT3 <- coef(lm_model)[3]
  r_squared <- summary(lm_model)$r.squared
  
  # Extract t-values and p-values
  t_value_WT2 <- summary(lm_model)$coefficients[2, "t value"]
  p_value_WT2 <- summary(lm_model)$coefficients[2, "Pr(>|t|)"]
  t_value_WT3 <- summary(lm_model)$coefficients[3, "t value"]
  p_value_WT3 <- summary(lm_model)$coefficients[3, "Pr(>|t|)"]
  
  # Store the results in the results data frame
  resultsHR2 <- rbind(resultsHR2, data.frame(id = subject_id,
                                             intercept = intercept,
                                             slope_WT2 = slope_WT2,
                                             t_value_WT2 = t_value_WT2,
                                             p_value_WT2 = p_value_WT2,
                                             slope_WT3 = slope_WT3,
                                             t_value_WT3 = t_value_WT3,
                                             p_value_WT3 = p_value_WT3,
                                             r_squared = r_squared,
                                             stringsAsFactors = FALSE))
}

dfHR1<-cbind(resultsHR1,dfQ)
dfHR2<-cbind(resultsHR2,dfQ)

#regressions for coefficients predicted by questionnaires
lm_CoefWT2 <- lm(slope_WT2 ~ MAIA1+MAIA2+MAIA3+MAIA4+MAIA5+MAIA6+MAIA7+MAIA8+TAS4+EQ, data=dfHR2)
summary(lm_CoefWT2)