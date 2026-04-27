
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
