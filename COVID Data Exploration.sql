-- This is an exploratory project about COVID-19
-- The data is downloaded from ourworldindata.org


-- Quick look at the tables
SELECT *
FROM CovidDeaths2023

SELECT *
FROM CovidVaccinations2023

-- Looking at the list of country based on continent
SELECT DISTINCT continent, location
FROM CovidDeaths2023
ORDER BY 1,2

SELECT DISTINCT continent, location
FROM CovidDeaths2023
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at the number of case and death per day
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths2023
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at the number of population infected by COVID-19 per day
SELECT location, date, population, total_cases, (total_cases/population)*100 AS infection_percentage
FROM CovidDeaths2023
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT location, MAX(total_cases) AS HighestCount, population, MAX((total_cases/population))*100 AS InfectionPercentage
FROM CovidDeaths2023
GROUP BY location, population
ORDER BY 4 DESC

--Showing the countries with the highest death count per population
SELECT continent, location, population, MAX(cast(total_deaths as int)) AS HighestCount
FROM CovidDeaths2023
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY 4 DESC

--Showing the continents with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) AS HighestCount
FROM CovidDeaths2023
WHERE continent IS NULL AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY HighestCount DESC

--Global data of number of cases and deaths
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths2023
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- Looking at vaccination rate
SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations
FROM CovidDeaths2023 AS ded
JOIN CovidVaccinations2023 AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
ORDER BY 2,3

-- Vaccination rate with a rolling total
SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS rolling_total
FROM CovidDeaths2023 AS ded
JOIN CovidVaccinations2023 AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
ORDER BY 2,3

--USE CTE for rolling vaccination rate
WITH vaxperpop (continent, location, date, population, new_vaccinations, rolling_total)
AS
(SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS rolling_total
FROM CovidDeaths2023 AS ded
JOIN CovidVaccinations2023 AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL
)
SELECT *, rolling_total/population*100 AS vax_percentage
FROM vaxperpop
ORDER BY 2,3

-- USE TEMP TABLE for rolling vaccination rate
DROP TABLE IF EXISTS #VaxRate
CREATE TABLE #VaxRate
(continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric,
rolling_total numeric)

INSERT INTO #VaxRate
SELECT ded.continent, ded.location, ded.date, ded.population, vax.new_vaccinations,
SUM(cast(vax.new_vaccinations as bigint)) OVER (PARTITION BY ded.location ORDER BY ded.location, ded.date) AS rolling_total
FROM CovidDeaths2023 AS ded
JOIN CovidVaccinations2023 AS vax
ON ded.location = vax.location
AND ded.date = vax.date
WHERE ded.continent IS NOT NULL

SELECT *, rolling_total/population*100 AS vax_rate
FROM #VaxRate
ORDER BY 2,3