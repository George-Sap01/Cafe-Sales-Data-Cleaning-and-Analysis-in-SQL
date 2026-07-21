# Cafe Sales Data Cleaning & Exploratory Data Analysis (SQL)

A comprehensive data cleaning, imputation, and exploratory analysis project using **MySQL** on a dirty sales dataset (`dirty_cafe_sales`) containing 10,000 transaction records.

---

##  Project Overview

This project demonstrates an end-to-end SQL workflow designed to transform messy, unstandardized cafe sales data into clean, structured tables ready for business intelligence and analytical reporting.

The project evaluates two distinct data handling approaches:
1. **`clean_table`**: Preserves original `'Unknown'` values in categorical fields (`payment_method`, `location`) to maintain raw data transparency.
2. **`clean_table2`**: Imputes missing/unknown categorical values using statistical **mode imputation** (most frequent valid category).

---

## Data Pipeline & Architecture

The workflow follows a 3-tier staging architecture:

```
┌────────────────────────┐
│   dirty_cafe_sales     │  <-- Raw CSV Data Import (10,000 Rows)
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│       staging1         │  <-- Data Auditing, RegEx String Cleaning & Calculation
└───────────┬────────────┘
            ├───────────────────────────────┐
            ▼                               ▼
┌────────────────────────┐     ┌────────────────────────┐
│      clean_table       │     │      clean_table2      │
│ (Explicit 'Unknown's)  │     │ (Mode-Imputed Category)│
└────────────────────────┘     └────────────────────────┘
```


1. **`dirty_cafe_sales`**: Uncleaned raw table containing missing values, malformed dates, and non-numeric garbage characters.
2. **`staging1`**: Staging environment used for regex pattern matching, algebraic reconstruction of missing financial fields, and string standardisation.
3. **`clean_table`**: Schema-enforced table with strongly-typed `ENUM` columns and validated dates.
4. **`clean_table2`**: Final enriched table featuring statistical mode imputation for `location` and `payment_method`.

---

## Data Cleaning Methodology 

### 1. Unique Identifier Validation
- Verified `transaction id` uniqueness across all 10,000 records.

### 2. Text Normalization & Standardisation
- Converted empty strings, `'ERROR'`, and `'UNKNOWN'` to `'Unknown'`.
- Trimmed whitespace across `item`, `payment method`, and `location` columns.

### 3. Numeric Data Sanitization & Mathematical Recovery
- Used REGEXP patterns to isolate non-numeric garbage data and convert them to `NULL`.
- Identified and **deleted 58 unrecoverable rows** where 2 or more financial metrics (`quantity`, `price_per_unit`, `total_spent`) were simultaneously missing.
- Reconstructed remaining single missing values algebraically:
  
$$\text{Quantity} = \frac{\text{Total Spent}}{\text{Price Per Unit}}$$

$$\text{Price Per Unit} = \frac{\text{Total Spent}}{\text{Quantity}}$$

$$\text{Total Spent} = \text{Quantity} \times \text{Price Per Unit}$$

### 4. Date Standardisation
- Flagged non-standard transaction dates using REGEXP and standardized placeholder dates (`1900-01-01`).

---

## Imputation Strategy 

To evaluate the impact of missing categorical attributes, `clean_table2` replaces missing values using Common Table Expressions (CTEs) based on the statistical **mode**:

- **Location Missingness**: ~39.63% (3,940 rows) imputed with the most frequent store location (`In-store` / `Takeaway`).
- **Payment Method Missingness**: ~31.76% (3,158 rows) imputed with the dominant payment method (`Credit Card` / `Digital Wallet` / `Cash`).

---

##  Analytical Capabilities & SQL Techniques

Both dataset versions feature analytical query suites executing key performance metrics:

- **Revenue Analysis**: Total revenue per item, month-over-month (MoM) revenue growth using `LAG()` window function.
- **Top Performers**: Ranked top 3 best-selling items by month, day of week, and 10-day period using `RANK() OVER (PARTITION BY ...)`.
- **Sales Distribution**: Daily revenue benchmarks against the annual average.
- **Rollup Aggregations**: Hierarchical multi-dimensional summaries using `WITH ROLLUP`.
- **Cross-Tabulation**: Pivot-style payment method counts per location using conditional aggregation (`SUM(CASE WHEN ...)`).

---

##  Repository Structure

```
├── Cleaning.sql                 # Staging creation, numeric sanitization & clean_table build
├── Clean_data_with_mode_2.sql   # Mode imputation CTEs & clean_table2 build
├── Queries on clean_table.sql   # EDA queries executed on clean_table
├── Queries on clean_table2.sql  # EDA queries executed on clean_table2
└── README.md                    # Project documentation
```

---

##  Key Takeaways & Impact

- **99.42% Data Retention**: Retained 9,942 out of 10,000 rows by using cross-column algebraic formulas rather than dropping incomplete records.
- **Strict Data Types**: Enforced strict MySQL `ENUM` and `DATE` types to ensure downstream integrity.
- **Dual Analytical Views**: Enabled comparing raw categorical distributions against mode-imputed datasets for robust business decision-making.

## Reference 
Dataset Source: <https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training>
