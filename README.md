# Vegetable Supermarket

## [Tableau Dashboard](https://public.tableau.com/app/profile/shreya.thacker6577/viz/VegetableSupermarketPart1/Dashboardpart1)

### Project Overview
Vegetable Supermarket is a data analysis project that aims to leverage SQL for data querying and Tableau for data visualization to gain insights into sales trends of three years of a fresh produce superstore located in China. 

The goal is to answer insightful questions that provides the business with actionable recommendations, thereby furthering its performance. 

The mock dataset for this project was acquired from [kaggle.com](https://www.kaggle.com/datasets/yapwh1208/supermarket-sales-data). 

### Tools and Environments
- Microsoft SQL Server Management Studio v18
- Tableau Public v2024

### Data description
The data is stored in four tables giving the following detail:

- The product category code and name, item code and name
- Transaction details including date and time of purchase, item information, the quantity sold, unit selling price, sale/return status, discount information
- The wholesale price at which the supermarket purchases its inventory
- The loss rate (presumably of the produce, although this is not made clear in the original dataset)

### Objectives 
To extract key metrics, the following questions were queried against the dataset:

#### Revenue-focused:
- How much is the revenue and how does it trend monthly and annually?
- What category of items are the most profitable to the store?
- How much does the supermarket spend in stocking its inventory at a wholesale price?
- What is the average unit selling price of each product? How does this change over months and years?
- How many items were purchased at a discounted cost?

#### Sales-focused:
- What is the count of purchased items at the category and individual product level? What is the trend looking like over different time periods?
- What are the top 10 products purchased within each category?
- Are there any items that are never sold?
- What products saw the most frequent returns?

### Project deliverables
- Import data into a database on SSMS. Organize, clean, and ready the data for exploration
- Use SQL to write multiple queries that help gain insights into the key metrics
- Build an interactive Tableau dashboard that presents the key metric analysis in a simple, understandable, and actionable format
- Provide supplemental charts and graphs for additional noteworthy takeaways 

### Code snippets
The entire SQL code file will be provided as a part of additional files, please peruse it. The following are only a few examples:

``` SQL
-- TOTAL QUANTITY SOLD FOR PRODUCTS PER CATEGORY (PER YEAR AND MONTH)

WITH CTE AS(
SELECT YEAR(s.Dateofsale) AS [Year],
       MONTH(s.Dateofsale) AS [Month],
       DATENAME(MONTH, (s.Dateofsale)) AS [Month Name],
       S.[Item Code],
       [Category Name], 
       [Item Name],
       COUNT(S.[Item Code]) AS NumberOfSales 
FROM TheSaleData S
INNER JOIN ItemCode C
       ON S.[Item Code] = C.[Item Code]
GROUP BY [Category Name], 
         S.[Item Code], 
       [Item Name],
       YEAR(s.Dateofsale),
       MONTH(s.Dateofsale),
       DATENAME(MONTH, (s.Dateofsale)))
		
SELECT CASE WHEN ([Year] = 2020) OR ([Year] = 2021 AND [Month] <= 6) THEN 'Year 1'
            WHEN ([Year] = 2021 AND [Month] > 6) OR ([Year] = 2022 AND [Month] <= 6) THEN 'Year 2'
            WHEN ([Year] = 2022 AND [Month] > 6) OR ([Year] = 2023 AND [Month] <= 6) THEN 'Year 3'
            ELSE NULL
            END AS [Year Cycle],
            *
INTO TotalQuantitySold
FROM CTE 
ORDER BY [Year Cycle], [Year], [Month], [Category Name], NumberOfSales DESC

SELECT * FROM TotalQuantitySold
ORDER BY [Year Cycle], [Year], [Month], [Category Name], NumberOfSales DESC
```

``` SQL
-- TOP SELLING PRODUCT BY SALES NUMBER (EACH MONTH) BY ITEM

WITH CTE AS(
            SELECT *,
            DENSE_RANK() OVER(PARTITION BY [year], [month] ORDER BY [numberofsales] desc) AS [Rank]
FROM TotalQuantitySold)

SELECT * FROM CTE 
WHERE [Rank] <= 10

-- TOP SELLING PRODUCT BY $$ (EACH MONTH) BY ITEM

WITH CTE AS(
            SELECT *,
            DENSE_RANK() OVER(PARTITION BY [year], [month] ORDER BY [Total Sale Amount] desc) AS [Rank]
FROM Monthly_Sale_Wholesale)

SELECT * FROM CTE
WHERE [Rank] <= 10
```
### Data Visualization
Please visit the [Tableau Dashboard](https://public.tableau.com/app/profile/shreya.thacker6577/viz/VegetableSupermarketPart1/Dashboardpart1) for an interactive experience

A few images of charts:
<p align="center">
  <img width="700" height="450" src="https://github.com/ShreyaThacker/Vegetable-Supermarket/blob/main/Screenshot%202024-05-27%20200826.png">
</p>

<p align="center">
  <img width="700" height="500" src="https://github.com/ShreyaThacker/Vegetable-Supermarket/blob/main/tables.png">
</p>

<p align="center">
  <img width="1000" height="600" src="https://github.com/ShreyaThacker/Vegetable-Supermarket/blob/main/top%205.jpg">
</p>
