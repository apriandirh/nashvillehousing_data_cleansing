/*

Cleaning Data in SQL Queries

*/

SELECT * FROM PortfolioProject..NashvilleHousing ORDER BY 1

--------------------------------------------------------------
-- Standarize Date Format

SELECT SaleDate FROM PortfolioProject..NashvilleHousing
SELECT SaleDate, CONVERT(Date, SaleDate) AS Date_Converted, SaleDate_Converted FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDate_Converted Date;

UPDATE NashvilleHousing SET SaleDate_Converted = CONVERT(Date, SaleDate)

--------------------------------------------------------------
-- Fillin NULL PropertyAddress

SELECT * FROM PortfolioProject..NashvilleHousing
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
WHERE a.PropertyAddress IS NULL AND b.PropertyAddress IS NOT NULL

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
WHERE a.PropertyAddress IS NULL AND b.PropertyAddress IS NOT NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing AS a
JOIN PortfolioProject..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
WHERE a.PropertyAddress IS NULL

--------------------------------------------------------------
-- Breaking out PropertyAddress to individual column

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing

SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
FROM PortfolioProject..NashvilleHousing

SELECT PropertyAddress, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1,  LEN(PropertyAddress)) AS Address
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD  PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1,  LEN(PropertyAddress))

SELECT * FROM NashvilleHousing

--------------------------------------------------------------
-- Breaking out OwnerAddress to individual column

SELECT * FROM NashvilleHousing

SELECT
OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------------
-- Change "Y" and "N" to "Yes" and "No" in SoldAsVacant Column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT 
SoldAsVacant,
CASE
WHEN
	SoldAsVacant = 'Y' THEN 'Yes'
WHEN
	SoldAsVacant = 'N' THEN 'No'
ELSE
	SoldAsVacant
END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant =
CASE
WHEN
	SoldAsVacant = 'Y' THEN 'Yes'
WHEN
	SoldAsVacant = 'N' THEN 'No'
ELSE
	SoldAsVacant
END
FROM NashvilleHousing

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--------------------------------------------------------------
-- Remove duplicate data

SELECT * FROM NashvilleHousing

WITH RowNumCTE AS (
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS Row_Num
FROM NashvilleHousing
)
SELECT * FROM RowNumCTE
WHERE Row_Num > 1
ORDER BY ParcelID

--------------------------------------------------------------
-- Delete unusued data

SELECT * FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, SaleDate

--------------------------------------------------------------
-- Export clean data to csv
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;

SELECT SERVERPROPERTY('Edition');




EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

INSERT INTO OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\Exports\NashvilleHousing_cleansed.xlsx;',
    'SELECT * FROM [Sheet1$]')
SELECT * FROM [PortfolioProject].[dbo].[NashvilleHousing_cleaned];
