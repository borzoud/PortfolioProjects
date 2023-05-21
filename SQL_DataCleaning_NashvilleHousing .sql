/*
Cleaning Data in SQL Queries
*/
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing

-- Standardize Date Format
SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing



ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateConverted	Date;

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

----------------------------------------------------------------------------------------------
-- -- Populate Property Address Area

SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- Finding replacable Null PropertAddress
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
			ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing AS a
JOIN PortfolioProject.dbo.NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Replacing nulls
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing AS a
JOIN PortfolioProject.dbo.NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-----------------------------------------------------------------------------------------------
-- -- Breaking out Address into individual columns (Address, City, State)
--Breaking out owner Address
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1 ) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1,LEN( PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing 


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress	NVARCHAR(255)
UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1 )


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity	NVARCHAR(255)
UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1,LEN( PropertyAddress)) 


-- Breaking out owner address
SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.') , 3),
PARSENAME(REPLACE(OwnerAddress, ',','.') , 2),
PARSENAME(REPLACE(OwnerAddress, ',','.') , 1)
FROM PortfolioProject.dbo.NashvilleHousing 

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress	NVARCHAR(255)
UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress= PARSENAME(REPLACE(OwnerAddress, ',','.') , 3)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity	NVARCHAR(255)
UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity= PARSENAME(REPLACE(OwnerAddress, ',','.') , 2)

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState	NVARCHAR(255)
UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.') , 1)


-----------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "SoldAsVacant" field

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing 
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant


SELECT
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant 
END AS SoldAsVacantCleaned
FROM PortfolioProject.dbo.NashvilleHousing 


UPDATE PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = (
		CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
			 ELSE SoldAsVacant 
		END)


-----------------------------------------------------------------------------------------------
-- Remove Duplicates
WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress, 
				 SalePrice, 
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID) AS row_num

FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE
--SELECT *
FROM RowNumCTE
WHERE row_num >1





-----------------------------------------------------------------------------------------------
-- Delete Unused Columns
SELECT  *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	



sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

USE PortfolioProject 
GO 

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 
GO 

EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 
GO 


---- Using BULK INSERT

USE PortfolioProject;
GO
BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
   WITH (
      FIELDTERMINATOR = ',',
      ROWTERMINATOR = '\n'
);
GO


---- Using OPENROWSET
USE PortfolioProject;
GO
SELECT * INTO nashvilleHousing
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0; Database=C:\Users\borzoud\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
GO
