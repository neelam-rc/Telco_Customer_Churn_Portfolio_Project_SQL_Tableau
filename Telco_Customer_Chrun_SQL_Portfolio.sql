-- =============================================
-- PROJECT OVERVIEW AND METADATA
-- =============================================

-- ===============================================================================================================
-- Project Name: Telco Customer Churn Analysis.
-- Source Data: IBM Telco Dataset (Kaggle).
-- Tools: SQL Server (T-SQL).
-- Objective: To clean raw telecommunications data and extract key performance indicators for customer retention.
-- ===============================================================================================================


-- =============================================
-- ENVIRONMENT SETUP & SCHEMA HARDENING
-- =============================================

USE Telco_Customer_Churn_IBM_Dataset;

-- Duplicated the table for EDA.
SELECT *
INTO Telco_Customer_Churn_Work
FROM Telco_Customer_Churn_T
;

SELECT *
FROM Telco_Customer_Churn_Work
;

-- Rounding the trailing decimal to 2 for charges column at the database schema.

ALTER TABLE Telco_Customer_Churn_Work
ALTER COLUMN [Monthly_Charges] DECIMAL(18, 2)
;
ALTER TABLE Telco_Customer_Churn_Work
ALTER COLUMN [Total_Charges] DECIMAL(18, 2)
;

-- Rounding the trailing decimal to 6 for Lat and Lang column at the database schema.
ALTER TABLE Telco_Customer_Churn_Work
ALTER COLUMN [Latitude] DECIMAL(18, 6)
;
ALTER TABLE Telco_Customer_Churn_Work
ALTER COLUMN [Longitude] DECIMAL(18, 6)
;


-- =============================================
-- DATA QUALITY & INTEGRITY AUDIT
-- =============================================

-- 1. Check for Duplicate Records
-- Ensuring each CustomerID is unique to prevent inflated metrics.
SELECT CustomerID
	 , COUNT(*)
FROM Telco_Customer_Churn_Work
GROUP BY CustomerID
HAVING COUNT(*) > 1
;

-- 2. Handling Nulls in Total_Charges
-- Note: Total_Charges is often blank for customers with 0 tenure.
-- We check for NULLs or empty strings to ensure calculation accuracy.
SELECT COUNT(*) AS Missing_Total_Charges
FROM Telco_Customer_Churn_Work
WHERE Total_Charges IS NULL OR Total_Charges = 0
;

-- Fix: Impute Total_Charges for new customers (Tenure = 0) 
-- Setting Total_Charges equal to Monthly_Charges for their first month.

UPDATE Telco_Customer_Churn_Work
SET Total_Charges = Monthly_Charges
WHERE Total_Charges IS NULL OR Total_Charges = 0;

-- Verification: Should now return 0
SELECT COUNT(*) AS Missing_Total_Charges
FROM Telco_Customer_Churn_Work
WHERE Total_Charges IS NULL OR Total_Charges = 0;

-- 3. Validation of Churn_Label vs Churn_Reason
-- Logic: If a customer churned (Yes), they must have a reason. 
-- If they didn't churn (No), the reason should be empty/null.
SELECT Churn_Label
	 , Churn_Reason
	 , COUNT(*) as Record_Count
FROM Telco_Customer_Churn_Work
GROUP BY Churn_Label, Churn_Reason
ORDER BY Churn_Label DESC
;

-- 4. Trimming whitespace
-- Preventing grouping errors in categorical columns like Payment_Method.
UPDATE Telco_Customer_Churn_Work
SET Payment_Method = TRIM(Payment_Method),
    Contract = TRIM(Contract),
    Internet_Service = TRIM(Internet_Service)
;


-- =============================================
-- BUSINESS SCENARIOS & DATA INSIGHTS
-- =============================================

-- Q1: What is the total count of churned customers and the total Monthly Revenue lost to the business?

SELECT COUNT(CASE
					WHEN Churn_Label = 'Yes' 
				    THEN CustomerID 
			END) AS Total_Churned_Customers --Total count of churned customers
     , SUM(CASE 
					WHEN Churn_Label = 'Yes' 
					THEN Monthly_Charges ELSE 0 
		  END) AS Total_Monthly_Revenue_Lost -- Total revenue lost (summing only churned charges)
     , CAST(
			(SUM(CASE 
					WHEN Churn_Label = 'Yes' 
				    THEN Monthly_Charges ELSE 0 
			END) / SUM(Monthly_Charges)) * 100.0
	   AS Decimal(10,2)) AS Revenue_Churn_Percentage  -- The percentage of churn rate by revenue
FROM Telco_Customer_Churn_Work
;

-- Q2: Which high-value customers (CLTV > 5000) have a churn score > 80 but are still active?

SELECT CustomerID
     , Gender
	 , Tenure_Months
	 , Churn_Score
	 , CLTV
	 , Contract
	 , Monthly_Charges
FROM Telco_Customer_Churn_Work
WHERE Churn_Label = 'No' 
	  AND CLTV > 5000 
	  AND Churn_Score >= 80
ORDER BY CLTV DESC
;

-- Q3: What is the average monthly charge of churned customers versus active customers? 

SELECT Churn_Label
     , CAST(AVG(Monthly_Charges) AS DECIMAL(10,2)) AS Avg_Monthly_Charges
     , COUNT(CustomerID) AS Total_Customers
FROM Telco_Customer_Churn_Work
GROUP BY Churn_Label
;

-- Q4: What is the total monthly revenue leakage by churn reason?

SELECT Churn_Reason 
     , SUM(Monthly_Charges) AS Total_Monthly_Revenue_Lost
     , COUNT(CustomerID) AS Churn_Count
     , CAST(SUM(Monthly_Charges) * 100.0 / SUM(SUM(Monthly_Charges)) OVER() AS DECIMAL(10,2)) AS Revenue_Loss_Percentage
FROM Telco_Customer_Churn_Work
WHERE Churn_Label = 'Yes'
GROUP BY Churn_Reason
ORDER BY Total_Monthly_Revenue_Lost DESC
;

-- Q5: What is the churn rate for fiber optic users (Impact of Security & Support)?

SELECT Tech_Support
	 , Online_Security
	 , COUNT(CustomerID) AS Total_Users
     , SUM(Churn_Value) AS Churned_Users
     , CAST(SUM(Churn_Value) * 100.0 / COUNT(CustomerID) AS DECIMAL(10,2)) AS Churn_Rate
FROM Telco_Customer_Churn_Work
WHERE Internet_Service = 'Fiber optic'
GROUP BY Tech_Support , Online_Security
ORDER BY Churn_Rate DESC
;

-- Q6: Find out total revenue leakage by Internet Service & Contract type?

SELECT Internet_Service
	 , Contract
     , SUM(Monthly_Charges) AS Total_Monthly_Revenue_Lost
     , COUNT(CustomerID) AS Churn_Count
     , CAST(SUM(Monthly_Charges) * 100.0 / SUM(SUM(Monthly_Charges)) OVER() AS DECIMAL(10,2)) AS Revenue_Loss_Percentage
FROM Telco_Customer_Churn_Work
WHERE Churn_Label = 'Yes'
GROUP BY Internet_Service, Contract
ORDER BY Total_Monthly_Revenue_Lost DESC
;

-- Q7: Find out churn rate by number of Add-On services like Online Security, Online Backup, Device Protection, 
--     Tech Support, Streaming TV, Streaming Movies

WITH ServiceCounts AS (
    SELECT CustomerID
         , Churn_Value 
         , (CASE WHEN Online_Security = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Online_Backup = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Device_Protection = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Tech_Support = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Streaming_TV = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN Streaming_Movies = 'Yes' THEN 1 ELSE 0 END) AS Add_On_Count
    FROM Telco_Customer_Churn_Work
)
SELECT Add_On_Count
     , COUNT(CustomerID) AS Total_Users
     , SUM(Churn_Value) AS Churned_Users 
     , CAST(AVG(CAST(Churn_Value AS DECIMAL(10,2))) * 100.0 AS DECIMAL(10,2)) AS Churn_Rate
FROM ServiceCounts
GROUP BY Add_On_Count
ORDER BY Add_On_Count ASC
;

-- Q8: Churn Rate by Payment Method Category (Automatic vs. Manual)?

SELECT (CASE
			WHEN Payment_Method IN ('Mailed check', 'Electronic check') THEN 'Manual'
			ELSE 'Automatic'
	   END) AS Payment_Category
	 , COUNT(CustomerID) AS Total_Users
     , SUM(Churn_Value) AS Churned_Users
	 , CAST(SUM(Churn_Value) * 100.0 / COUNT(CustomerID)AS DECIMAL(10,2)) AS Churn_Rate
FROM Telco_Customer_Churn_Work
GROUP BY (CASE
			WHEN Payment_Method IN ('Mailed check', 'Electronic check') THEN 'Manual'
			ELSE 'Automatic'
	     END)
ORDER BY Churn_Rate DESC
;

-- Q9: Compare average tenure and identify the month with the highest churn volume.
-- Part A: Average tenure comparison
SELECT Churn_Label
	 , COUNT(CustomerID) AS Total_Users
     , AVG(Tenure_Months) AS Avg_Tenure_Months
FROM Telco_Customer_Churn_Work
GROUP BY Churn_Label
;

-- Part B: Identifying the churn spike month
SELECT TOP 5 Tenure_Months
	 , COUNT(CustomerID) AS Churned_Customer_Count
FROM Telco_Customer_Churn_Work
WHERE Churn_Label = 'Yes'
GROUP BY Tenure_Months
ORDER BY Churned_Customer_Count DESC
;

-- Q10: Identify top-5 high-risk cities and determine if competition or pricing is the cause.

SELECT TOP 5 City
     , COUNT(CustomerID) AS Total_Customers
     , CAST(AVG(CAST(Churn_Value AS DECIMAL(10,2))) * 100.0 AS DECIMAL(10,2)) AS Churn_Rate
     , (SELECT TOP 1 Churn_Reason 
       FROM Telco_Customer_Churn_Work AS sub 
       WHERE sub.City = main.City AND sub.Churn_Label = 'Yes'
       GROUP BY Churn_Reason 
       ORDER BY COUNT(*) DESC) AS Primary_Churn_Reason		-- Identify the most common churn reason in that specific city

FROM Telco_Customer_Churn_Work AS main
GROUP BY City
HAVING COUNT(CustomerID) >= 30								-- Statistical significance filter
ORDER BY Churn_Rate DESC
;

-- Q11: Compare Churn Reasons and Payment Preferences between Seniors and Non-Seniors.
-- Part A: Top Churn Reasons by Senior Citizen Status
SELECT Senior_Citizen
     , Churn_Reason
	 , COUNT(CustomerID) Customer_Churn_Count
FROM Telco_Customer_Churn_Work
WHERE Churn_Label = 'Yes'
GROUP BY Senior_Citizen, Churn_Reason
ORDER BY Senior_Citizen DESC, Customer_Churn_Count DESC
;

-- Part B: Payment Method Preferences by Senior Citizen Status
SELECT Senior_Citizen
     , Payment_Method
     , COUNT(CustomerID) AS User_Count
     , CAST(COUNT(CustomerID) * 100.0 / SUM(COUNT(CustomerID)) OVER(PARTITION BY Senior_Citizen) AS DECIMAL(10,2)) AS Preference_Percentage
FROM Telco_Customer_Churn_Work
GROUP BY Senior_Citizen, Payment_Method
ORDER BY Senior_Citizen DESC, Preference_Percentage DESC
;

-- ==========================================================
-- THANK YOU
-- ==========================================================