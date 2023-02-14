--SELECT *
--FROM CovidDeaths

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4

--Select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at the list of countries
SELECT DISTINCT location, continent
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY continent, location

-- Looking at total cases and total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
ORDER BY 1,2

-- Looking at cases based on location

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Indonesia'
ORDER BY 1,2

-- Looking at the percentage of population that got covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectionPercentage
FROM CovidDeaths
WHERE location = 'Indonesia'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT location, MAX(total_cases) AS HighestCount, population, MAX((total_cases/population))*100 AS InfectionPercentage
FROM CovidDeaths
--WHERE location = 'Indonesia'
GROUP BY location, population
ORDER BY 4 DESC

--Showing the countries with the highest death count per population
SELECT continent, location, population, MAX(cast(total_deaths as int)) AS HighestCount
FROM CovidDeaths
--WHERE location = 'Indonesia'
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY 1,2,3 DESC

--Showing the continents with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) AS HighestCount
FROM CovidDeaths
--WHERE location = 'Indonesia'
WHERE continent IS NULL
GROUP BY location
ORDER BY HighestCount DESC

--SELECT continent, HighestCount
--FROM (
--	SELECT continent, location, population, SUM(cast(total_deaths as int)) AS HighestCount
--FROM CovidDeaths)
----WHERE location = 'Indonesia'
--GROUP BY continent
--ORDER BY 1,2,3 DESC
	
--WHERE location = 'Indonesia'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 3 DESC

-- Global numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
--WHERE location = 'Indonesia'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- EXPLORE VACCINATION TABLE
SELECT *
FROM CovidVaccinations
ORDER BY continent, location, date

-- JOIN Deaths and Vaccinations
SELECT *
FROM CovidDeaths AS ded
JOIN CovidVaccinations AS vax
ON ded.location = vax.location
AND ded.date = vax.date

-- Looking at vaccination rate
SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations
FROM CovidDeaths AS ded
JOIN CovidVaccinations AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
ORDER BY 2,3

SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as int)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS new_total
FROM CovidDeaths AS ded
JOIN CovidVaccinations AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
ORDER BY 2,3

--USE CTE
WITH vaxperpop (continent, location, date, population, new_vaccinations, new_total)
AS
(SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as int)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS new_total
FROM CovidDeaths AS ded
JOIN CovidVaccinations AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
)
SELECT *, new_total/population*100 AS vax_percentage
FROM vaxperpop
ORDER BY 2,3

-- USE TEMP TABLE
CREATE TABLE #VaxPercentage
(continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric,
new_total numeric)

INSERT INTO #VaxPercentage
SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as int)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS new_total
FROM CovidDeaths AS ded
JOIN CovidVaccinations AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL

SELECT *, new_total/population*100 AS vax_percentage
FROM #VaxPercentage
ORDER BY 2,3

-- CREATE VIEW
CREATE VIEW VaxPercent AS
SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as int)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS new_total
FROM CovidDeaths AS ded
JOIN CovidVaccinations AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
--ORDER BY 2,3