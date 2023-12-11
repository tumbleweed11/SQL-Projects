-- Data from Table1
SELECT *
FROM CovidProject..CovidDeaths


-- Looking at Total Cases vs Total Deaths.
-- Shows likelihood of dying if you contract Covid in your Country.

SELECT location, date, total_cases, total_deaths, (CONVERT(float,total_deaths))/(CONVERT(float,total_cases))*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE location like 'India' AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Cases vs Population.
-- Shows what percentage of population got Covid.

SELECT location, date, population, total_cases, (CONVERT(float,total_cases))/(CONVERT(float,population))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
WHERE location like 'India' AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to population.

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((CONVERT(float,total_cases))/(CONVERT(float,population)))*100 AS PercentPopulationInfected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Showing Countries with Highest Death Count per Population.

SELECT location, MAX(CONVERT(bigint,total_deaths)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Let's break this down by Continent and other groups of population.

SELECT location, MAX(CONVERT(bigint,total_deaths)) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing continents with the highest death count per population.

SELECT continent, SUM(new_deaths) AS TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers.

SELECT  SUM(new_cases) AS total_cases,
		SUM(CAST(new_deaths AS bigint)) AS total_deaths, 
		CASE
			WHEN SUM(new_cases) = 0 THEN NULL
			ELSE SUM(CAST(new_deaths AS bigint))/SUM(new_cases)*100
		END AS DeathPercentage
FROM CovidProject..CovidDeaths


-- Data from Table2

SELECT *
FROM CovidProject..CovidVaccinations


-- Total Population vs Vaccinations.
-- USING CTE.

WITH PopvsVac (continent, location, date, population, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingPercentageVaccinated
FROM PopvsVac

-- Total Population vs Vaccinations.
-- USING Temp Table.

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingPercentageVaccinated
FROM #PercentPopulationVaccinated







-- Creating View to store data for later visualisation.

--1

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
ON  dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


--2

CREATE VIEW GlobalNumbers AS
SELECT  SUM(new_cases) AS total_cases,
		SUM(CAST(new_deaths AS bigint)) AS total_deaths, 
		CASE
			WHEN SUM(new_cases) = 0 THEN NULL
			ELSE SUM(CAST(new_deaths AS bigint))/SUM(new_cases)*100
		END AS DeathPercentage
FROM CovidProject..CovidDeaths