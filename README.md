# Telco Customer Churn: Finding Why Customers Leave

![Dashboard Preview](Github Telco Customer Churn Portfolio Project.png)

### [View Tableau Dashboard](https://public.tableau.com/app/profile/neelamrc/viz/TelcoChurnAnalysisRetentionBlueprintDecodingTelcoChurnDriversviz/Telco_Dashboard_v1) | [View SQL Scripts](https://github.com/neelam-rc)

## Project Overview
It is way cheaper to keep a customer than to find a new one. In this project, I analyzed a dataset of 7000+ telecom customers in California to figure out what is driving people to cancel their services. I used SQL to clean and prep the data and Tableau to build a dashboard that shows exactly where the business is losing money.

## How I Solved It
* **Data Prep**: I handled 72 months of data in SQL Server. I used window functions and CTEs to clean up the records and grouped people into tenure segments like "0 to 6 months" and "2+ years" to see who is most likely to leave.

* **Cleaning**: I fixed schema issues with billing columns (Decimal precision) and imputed missing values for new customers with 0 tenure. I also sanitized categorical data to ensure churn values were ready for analysis.

* **Dashboarding**: I built a dark themed dashboard in Tableau that focuses on the big numbers: Churn Rate, Customer Lifetime Value (CLTV), and Monthly Revenue Loss.

## Key Insights
* **The Big Picture**: The churn rate is sitting at 26.5%. That means 1,869 people walked away.
* **The Month-1 Cliff**: Customers in their first month churn at 8x the rate of those with a 2-year tenure, making onboarding the highest-ROI retention action.
* **Contract Risks**: People on month-to-month contracts are way more likely to leave, especially Fiber Optic users who show a 54.6% churn rate.
* **Money on the Table**: The average CLTV is about 4,400. Reducing churn even slightly saves the company significant revenue.
* **Why They Leave**: A lot of people left because a competitor had a better offer or they simply moved.

## Tools I Used
* **SQL Server**: For all the heavy lifting, data cleaning, and scenario logic.
* **Tableau**: For the interactive visuals and final executive dashboard.
* **Excel**: Used for initial data audit and schema planning.

## Author: Neelam Chaudhari
I am a professional with over 3 years of corporate experience as a SQL Database Administrator transitioning into Data Analytics. This project is a centerpiece of my technical portfolio.

## Links
* **LinkedIn**: [Neelam Chaudhari](https://www.linkedin.com/in/neelamrc)
* **Tableau Public**: [My Portfolio](https://public.tableau.com/app/profile/neelamrc)
* **GitHub**: [Project Repository](https://github.com/neelam-rc)

Thank You!
