use [Supermarket sales]

SELECT * FROM TheSaleData

SELECT * FROM LossRate

SELECT * FROM TheWholesalePrice

SELECT * FROM ItemCode


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
		--ORDER BY [Year], [Month], [Category Name], COUNT(S.[Item Code]) DESC

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

---------------------------------------------------------------------------------------------------------------
-- TOTAL REVENUE FOR PRODUCTS PER CATEGORY (PER YEAR AND MONTH)


-- Part 1 sale and wholesale amount per transaction comparison

DROP TABLE IF EXISTS SalesVsWholesale
SELECT S.[Item Code], 
	   C.[Category Name],
	   C.[Item Name],
	   S.DateOfSale,
	   [Quantity Sold (kilo)],
	   [Unit Selling Price (RMB/kg)],
	   ([Quantity Sold (kilo)] * [Unit Selling Price (RMB/kg)]) AS [Total Sale Amount (RMB)],
	   [Wholesale Price (RMB/kg)],
	   ([Quantity Sold (kilo)] * [Wholesale Price (RMB/kg)]) AS [Total Wholesale Amount (RMB)]
INTO SalesVsWholesale
FROM TheSaleData S
JOIN TheWholesalePrice W
	ON S.[Item Code] = W.[Item Code]
	AND S.DateOfSale = W.DateOfSale
JOIN ItemCode C
	ON S.[Item Code] = C.[Item Code]
order by DateOfSale

SELECT * FROM SalesVsWholesale

-- Part 2 TOTAL REVENUE per year, month, category. sale and wholesale side-by-side comparison. can get net profit.

DROP TABLE IF EXISTS Monthly_Sale_Wholesale
SELECT DATEPART(YEAR, DateOfSale) AS [Year],
	   DATEPART(MONTH, DateOfSale) AS [Month],
	   DATENAME(MONTH, DateOfSale) AS [Month Name],
	   [Item Code],
	   [Category Name],
	   [Item Name],
	   ROUND(SUM([Total Sale Amount (RMB)]), 2) AS [Total Sale Amount],
	   ROUND(SUM ([Total Wholesale Amount (RMB)]),2) AS [Total Wholesale Amount]
INTO Monthly_Sale_Wholesale
FROM SalesVsWholesale
GROUP BY [Item Code],
	     [Category Name],
	     [Item Name],
	     DATEPART(YEAR, DateOfSale),
	     DATEPART(MONTH, DateOfSale),
		 DATENAME(MONTH, DateOfSale)
ORDER BY [Year], [Month]

SELECT * FROM Monthly_Sale_Wholesale ORDER BY [Year], [Month], [Category Name], [Total Sale Amount] DESC  
----------------------------------------------------------------------------------------------------------

-- TOTAL PROFIT per YEAR, MONTH, ITEM

SELECT *,
	   ([Total Sale Amount] - [Total Wholesale Amount]) AS Profit
FROM Monthly_Sale_Wholesale 
ORDER BY [Year], [Month], [Category Name], [Total Sale Amount] DESC

-- TOTAL PROFIT per YEAR, MONTH, CATEGORY (the CTE is total profit, the rank is top 1 total profit by category)

WITH CTE AS(
		SELECT [Year], [Month], [Category Name],
			   SUM(([Total Sale Amount] - [Total Wholesale Amount])) AS TotalProfit
		FROM Monthly_Sale_Wholesale
		group by [YEAR], [MONTH], [Category Name])
		
SELECT *,
	   DENSE_RANK() OVER(PARTITION BY [Year], [Month] ORDER BY TotalProfit desc) AS [Rank] 
FROM CTE

--------------------------------------------------------------------------------------------------------

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

SELECT * FROM CTE --WHERE [Rank] = 1
WHERE [Rank] <= 10
--------------------------------------------------------------------------------------------------------

--WHICH ITEMS WENT ON PROMOTIONAL OFFERS (DISCOUNTS) AND HOW MANY ITEMS WERE PURCHASED ON THOSE OFFERS as compared to totalquantitysold

SELECT YEAR(Dateofsale) AS [Year],
	   MONTH(DateofSale) AS [Month],
	   DATENAME(MONTH, DateofSale) AS [Month Name],
	   s.[Item Code],
	   [Category Name],
	   [Item Name],
	   SUM(CASE WHEN S.[Quantity Sold (kilo)] IS NULL THEN 0 ELSE 1 END) AS [Number of Products sold],
	   SUM(CASE WHEN [discount (yes/no)] = 'Yes' THEN 1 ELSE 0 END) AS [Number of Promotional offers]
FROM TheSaleData S
JOIN ItemCode C
	ON S.[Item Code] = C.[Item Code]
GROUP BY YEAR(Dateofsale),
	   MONTH(DateofSale),
	   s.[Item Code],
	   [Category Name],
	   [Item Name],
	   DATENAME(MONTH, DateofSale)
ORDER BY [Year], [Month], [Category Name], [Number of Products sold] DESC

-- ALTERNATE VERSION FOR TABLEAU

SELECT * 
FROM(
		SELECT *,
			   DENSE_RANK() OVER(PARTITION BY [category name], [year], [month] ORDER BY [Number of Promotional offers] desc) AS [highest promotional offers]
		FROM (SELECT YEAR(Dateofsale) AS [Year],
					  MONTH(DateofSale) AS [Month],
					  DATENAME(MONTH, DateofSale) AS [Month Name],
					  s.[Item Code],
					  [Category Name],
					  [Item Name],
					  [discount (yes/no)],
					  -- SUM(CASE WHEN S.[Quantity Sold (kilo)] IS NULL THEN 0 ELSE 1 END) AS [Number of Products sold],
					  COUNT([discount (yes/no)]) AS [Number of Promotional offers]
			  FROM TheSaleData S
			  JOIN ItemCode C
			  	ON S.[Item Code] = C.[Item Code]
			  GROUP BY YEAR(Dateofsale),
			  	   MONTH(DateofSale),
			  	   s.[Item Code],
			  	   [Category Name],
			  	   [Item Name],
			  	   DATENAME(MONTH, DateofSale),
			  	   [discount (yes/no)]) AS A) AS B
WHERE [highest promotional offers] <= 3
ORDER BY [Year], [Month], [Category Name], [highest promotional offers]


------------------------------------------------------------------------------------------------------------
-- NUMBER OF RETURNS

SELECT YEAR(Dateofsale) AS [Year],
	   MONTH(DateofSale) AS [Month],
	   DATENAME(MONTH, DateofSale) AS [Month Name],
	   S.[Item Code],
	   C.[Category Name],
	   C.[Item Name], 
	   SUM(CASE WHEN s.[Sale or Return] = 'sale' THEN 0
				ELSE 1
				END) AS [Number of Returns]
FROM TheSaleData S
JOIN ItemCode C
	ON S.[Item Code] = C.[Item Code]
GROUP BY YEAR(Dateofsale),
	     MONTH(DateofSale),
	     DATENAME(MONTH, DateofSale),
	     S.[Item Code],
	     C.[Category Name],
	     C.[Item Name]
ORDER BY 1,2, [Number of Returns] DESC
--------------------------------------------------------------------------------------------------------------
-- AVERAGE UNIT SELLING PRICE

DROP TABLE IF EXISTS AverageUnitSellingPrice
SELECT --Q.[Year Cycle],
	   YEAR(Dateofsale) AS [Year],
	   MONTH(DateofSale) AS [Month],
	   --DATENAME(MONTH, DateofSale) AS [Month Name],
	   S.[Item Code],
	   --C.[Category Name],
	   C.[Item Name], 
	   ROUND(AVG(s.[Unit Selling Price (RMB/kg)]), 2) AS [AverageSellingPrice (RMB)/kg],
	   --SUM(s.[Unit Selling Price (RMB/kg)])/COUNT(S.[Item Code]),
	   COUNT(S.[Item Code]) AS [Number of items Sold]
--INTO AverageUnitSellingPrice
FROM TheSaleData S
JOIN ItemCode C
	ON S.[Item Code] = C.[Item Code]
JOIN TotalQuantitySold Q
	ON Q.[Item Code] = S.[Item Code]
GROUP BY S.[Item Code], 
	     C.[Item Name],
		 --C.[Category Name],
		 --[Year Cycle]
		 YEAR(Dateofsale),
	     MONTH(DateofSale)
	     --DATENAME(MONTH, DateofSale)
ORDER BY 1, [AverageSellingPrice (RMB)/kg] DESC


SELECT * FROM AverageUnitSellingPrice
ORDER BY 1,2,5, [Number of items Sold] DESC, [AverageSellingPrice (RMB)/kg] DESC

--------------------------------------------------------------------------------------------------------------
-- REVENUE SPLIT BY CATEGORY EACH MONTH, YEAR

SELECT [Year], [Month], [Category Name],
	   SUM([Total Sale Amount]) AS TotalRevenue,
	   SUM([Total Sale Amount])/SUM(SUM([Total Sale Amount])) OVER (PARTITION BY [Year], [month]) AS PercentRevenue,
	   FORMAT(SUM([Total Sale Amount])/SUM(SUM([Total Sale Amount])) OVER (PARTITION BY [Year], [month]), 'p')
FROM Monthly_Sale_Wholesale
GROUP BY [YEAR], [MONTH], [Category Name]