"""1. Anomaly Detection – Isolation Forest
This script identifies suspicious payroll records such as **“too perfect”** timesheets or **abnormal patterns** submitted by employers.
"""

import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
import matplotlib.pyplot as plt

# 1. Generate mock payroll data (Normal vs Suspicious)
np.random.seed(42)
n_samples = 500

# Normal data: working hours with natural variability
normal_data = pd.DataFrame({
    'avg_daily_hours': np.random.normal(7.6, 0.5, n_samples),
    'std_daily_hours': np.random.normal(0.8, 0.2, n_samples),  # volatility of daily hours
    'overtime_ratio': np.random.uniform(0.05, 0.15, n_samples)
})

# Suspicious data (Anomalies):
# 1. Almost zero variability → “too perfect” (possible manipulation)
# 2. Overtime ratio abnormally zero
outliers = pd.DataFrame({
    'avg_daily_hours': [7.6, 7.6, 8.0, 7.5],
    'std_daily_hours': [0.01, 0.02, 0.01, 0.03],  # almost no volatility
    'overtime_ratio': [0.0, 0.0, 0.0, 0.0]
})

df = pd.concat([normal_data, outliers], ignore_index=True)

# 2. Train Isolation Forest model
# contamination: expected proportion of anomalies (approx. 1%)
model = IsolationForest(contamination=0.01, random_state=42)
df['anomaly_score'] = model.fit_predict(df[['avg_daily_hours', 'std_daily_hours', 'overtime_ratio']])

# -1 = anomaly, 1 = normal
df['is_anomaly'] = df['anomaly_score'].map({1: 'Normal', -1: 'Anomaly'})

# 3. Visualization (for interview demo)
plt.scatter(
    df['avg_daily_hours'], df['std_daily_hours'],
    c=(df['anomaly_score'] == -1), cmap='coolwarm', alpha=0.6
)
plt.title("Fraud Detection: Identifying 'Too Perfect' Payroll Records")
plt.xlabel("Average Daily Hours")
plt.ylabel("Standard Deviation of Hours (Volatility)")
plt.show()

print(df[df['is_anomaly'] == 'Anomaly'])


"""### 2. High-Risk Business Prediction (Risk Scoring) – XGBoost
This script learns from past breach history and business characteristics to estimate the **breach probability (Risk Score)** for businesses that have not yet been investigated.
"""

import pandas as pd
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

# 1. Generate mock business dataset
# Features: industry, employee count, complaint count, regional risk, years active
data = {
    'industry': ['Hospitality', 'Retail', 'Construction', 'Hospitality', 'Retail', 'Cleaning', 'Construction'],
    'emp_count': [15, 30, 50, 5, 100, 20, 200],
    'complaints': [3, 1, 0, 5, 2, 8, 1],
    'region_risk': [0.8, 0.4, 0.2, 0.9, 0.5, 0.7, 0.3],
    'years_active': [2, 10, 15, 1, 20, 3, 12],
    'is_breach': [1, 0, 0, 1, 0, 1, 0]  # Target: breach or not
}

df_risk = pd.DataFrame(data)

# 2. Preprocessing (Categorical Encoding)
le = LabelEncoder()
df_risk['industry'] = le.fit_transform(df_risk['industry'])

X = df_risk.drop('is_breach', axis=1)
y = df_risk['is_breach']

# 3. Train XGBoost model
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

model_xgb = xgb.XGBClassifier(n_estimators=100, learning_rate=0.1, max_depth=3)
model_xgb.fit(X_train, y_train)

# 4. Compute risk scores (breach probability)
df_risk['risk_score'] = model_xgb.predict_proba(X)[:, 1]

# Sort by highest risk (Prioritization)
priority_list = df_risk.sort_values(by='risk_score', ascending=False)

print("--- High-Risk Business Prioritization List ---")
print(priority_list[['industry', 'complaints', 'risk_score']])

# 5. Feature Importance (Which factors increase risk? Basic XAI)
xgb.plot_importance(model_xgb)
plt.show()
