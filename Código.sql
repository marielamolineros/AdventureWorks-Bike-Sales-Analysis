use AdventureWorks2017;
---PARTE I: SERIES TEMPORALES
-- Consulta base
SELECT
 FORMAT(SOH.OrderDate, 'dd/MM/yyyy') AS OrderDate,
 SUM(SOD.LineTotal) AS Sales
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD
ON SOH.SalesOrderID = SOD.SalesOrderID
WHERE YEAR(SOH.OrderDate) BETWEEN 2011 AND 2014
GROUP BY FORMAT(SOH.OrderDate, 'dd/MM/yyyy')
ORDER BY MIN(SOH.OrderDate);
--Subconsulta por región: USA
SELECT
SUM(IIF(TER.[GROUP] = 'North America', SOD.LineTotal, 0)) AS SalesUSA
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD
ON SOH.SalesOrderID = SOD.SalesOrderID
LEFT JOIN Sales.SalesTerritory TER
ON TER.TerritoryID = SOH.TerritoryID;
--Subconsulta por región: Europe
SELECT
SUM(IIF(TER.[GROUP] = 'Europe', SOD.LineTotal, 0)) AS SalesEU
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD
ON SOH.SalesOrderID = SOD.SalesOrderID
LEFT JOIN Sales.SalesTerritory TER
ON TER.TerritoryID = SOH.TerritoryID;
--Subconsulta por región: Pacific
SELECT
SUM(IIF(TER.[GROUP] = 'Pacific', SOD.LineTotal, 0)) AS SalesPac
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD
ON SOH.SalesOrderID = SOD.SalesOrderID
LEFT JOIN Sales.SalesTerritory TER
ON TER.TerritoryID = SOH.TerritoryID;

-- Serie Temporal VentasPorRegion Total
SELECT
FORMAT(SOH.OrderDate, 'dd/MM/yyyy') AS OrderDate,
 SUM(SOD.LineTotal) AS Sales,
 SUM(IIF(TER.[GROUP] = 'North America', SOD.LineTotal, 0)) AS SalesUSA,
 SUM(IIF(TER.[GROUP] = 'Europe', SOD.LineTotal, 0)) AS SalesEU,
 SUM(IIF(TER.[GROUP] = 'Pacific', SOD.LineTotal, 0)) AS SalesPac
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD
ON SOH.SalesOrderID = SOD.SalesOrderID
LEFT JOIN Sales.SalesTerritory TER
ON TER.TerritoryID = SOH.TerritoryID
WHERE YEAR(SOH.OrderDate) BETWEEN 2011 AND 2014
GROUP BY FORMAT(SOH.OrderDate, 'dd/MM/yyyy')
ORDER BY MIN(SOH.OrderDate);
PARTE II: DATASET DE CLIENTES PARA REGRESION LINEAL


--PARTE II: DATASET DE CLIENTES PARA REGRESION LINEAL
WITH ClientesIndividuos AS (
 SELECT
 SOH.SubTotal AS TotalAmount,
 SOH.CustomerID,
 ST."Name" AS Country,
 ST.CountryRegionCode,
 ST."Group",
 P.BusinessEntityID AS PersonID,
 P.PersonType,
 DATEDIFF(YEAR, PD.BirthDate, GETDATE()) - 4 AS Age
 FROM Sales.SalesOrderHeader SOH
 INNER JOIN Sales.Customer CU ON CU.CustomerID = SOH.CustomerID
 INNER JOIN Person.Person P ON P.BusinessEntityID = CU.PersonID
 INNER JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
 LEFT JOIN Sales.vPersonDemographics PD ON P.BusinessEntityID =
PD.BusinessEntityID
 WHERE P.PersonType = 'IN'
)
SELECT
 SUM(CI.TotalAmount) AS TotalAmount,
 CI.CustomerID,
 CI.Country,
 CI.CountryRegionCode,
 CI."Group",
 CI.PersonID,
 CI.PersonType,
 FORMAT(PD.DateFirstPurchase, 'dd/MM/yyyy') AS DateFirstPurchase,
 FORMAT(PD.BirthDate, 'dd/MM/yyyy') AS BirthDate,
 CI.Age,
 PD.MaritalStatus,
 PD.YearlyIncome,
 PD.Gender,
 PD.totalChildren,
 PD.Education,
 PD.Occupation,
 PD.HomeOwnerFlag,
 PD.NumberCarsOwned
FROM ClientesIndividuos CI
INNER JOIN Sales.vPersonDemographics PD ON CI.PersonID = PD.BusinessEntityID
GROUP BY PD.TotalPurchaseYTD, CI.CustomerID, CI.Country,
 CI.CountryRegionCode,
 CI."Group",
 CI.PersonID,
 CI.PersonType,
 DateFirstPurchase,
 BirthDate,
 CI.Age,
 PD.MaritalStatus,
 PD.YearlyIncome,
 PD.Gender,
 PD.totalChildren,
 PD.Education,
 PD.Occupation,
 PD.HomeOwnerFlag,
 PD.NumberCarsOwned
ORDER BY CI.CustomerID ASC, CI.Country ASC, DateFirstPurchase ASC;
PARTE III: DATASET DE CLIENTES PARA CLASIFICACIÓN (REGRESIÓN LOGÍSTICA)

--PARTE III: DATASET DE CLIENTES PARA CLASIFICACIÓN (REGRESIÓN LOGÍSTICA)
WITH ClientesIndividuos AS (
 SELECT
 SOH.SubTotal AS TotalAmount,
 CASE WHEN MAX(CASE WHEN PS.ProductSubcategoryID IN (1, 2, 3) THEN 1
ELSE 0 END) OVER (PARTITION BY SOH.CustomerID) > 0 THEN 1 ELSE 0 END AS
BikePurchasing,
 SOH.CustomerID,
 ST."Name" AS Country,
 ST.CountryRegionCode,
 ST."Group",
 P.BusinessEntityID AS PersonID,
 P.PersonType,
 DATEDIFF(YEAR, PD.BirthDate, GETDATE()) - 4 AS Age
 FROM
 Sales.SalesOrderHeader SOH
 INNER JOIN Sales.Customer CU ON CU.CustomerID = SOH.CustomerID
 INNER JOIN Person.Person P ON P.BusinessEntityID = CU.PersonID
 INNER JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
 INNER JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID =
SOD.SalesOrderID
 INNER JOIN Production.Product PP ON SOD.ProductID = PP.ProductID
 INNER JOIN Production.ProductSubcategory PS ON PP.ProductSubcategoryID
= PS.ProductSubcategoryID
 LEFT JOIN Sales.vPersonDemographics PD ON P.BusinessEntityID =
PD.BusinessEntityID
 WHERE P.PersonType = 'IN'
)

SELECT
 SUM(CI.TotalAmount) AS TotalAmount,
 CI.BikePurchasing,
 CI.CustomerID,
 CI.Country,
 CI.CountryRegionCode,
 CI."Group",
 CI.PersonID,
 CI.PersonType,
 FORMAT(PD.DateFirstPurchase, 'dd/MM/yyyy') AS DateFirstPurchase,
 FORMAT(PD.BirthDate, 'dd/MM/yyyy') AS BirthDate,
 CI.Age,
 PD.MaritalStatus,
 PD.YearlyIncome,
 PD.Gender,
 PD.totalChildren,
 PD.Education,
 PD.Occupation,
 PD.HomeOwnerFlag,
 PD.NumberCarsOwned
FROM ClientesIndividuos CI
INNER JOIN Sales.vPersonDemographics PD ON CI.PersonID = PD.BusinessEntityID
GROUP BY PD.TotalPurchaseYTD, CI.CustomerID, CI.Country,
 CI.BikePurchasing,
 CI.CountryRegionCode,
 CI."Group",
 CI.PersonID,
 CI.PersonType,
 DateFirstPurchase,
 BirthDate,
 CI.Age,
 PD.MaritalStatus,
 PD.YearlyIncome,
 PD.Gender,
 PD.totalChildren,
 PD.Education,
 PD.Occupation,
 PD.HomeOwnerFlag,
 PD.NumberCarsOwned
ORDER BY DateFirstPurchase ASC;