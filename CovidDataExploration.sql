SELECT *
FROM PortfolioProject..CovidDeaths$
ORDER BY 3,4

-- select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
ORDER BY 1, 2


-- looking at total cases vs total deaths
-- shows the probability of death if you catch covid in your country

SELECT continent, location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1, 2

SELECT continent, location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM PortfolioProject..CovidDeaths$
WHERE location = 'Indonesia' AND continent IS NOT NULL
ORDER BY 1, 2


-- looking at total cases vs population
SELECT continent, location, date, population, total_cases, (total_cases/population)*100 AS infection_rate
FROM PortfolioProject..CovidDeaths$
WHERE location = 'Indonesia' AND continent IS NOT NULL
ORDER BY 1, 2


-- looking at countries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS infection_rate
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY 4 DESC


-- looking at infection rate over time
SELECT location, date, population, total_cases,  (total_cases/population)*100 AS infection_rate
FROM PortfolioProject..CovidDeaths$
ORDER BY 1,2


-- shows the countries with highest death count per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS highest_death_count
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC


-- by continent
SELECT location, MAX(CAST(total_deaths AS INT)) AS highest_death_count
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY 2 DESC


-- global numbers
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_rate
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1, 2

SELECT location, SUM(CAST(new_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
AND location not in ('International', 'World', 'European Union')
GROUP BY location
ORDER BY 2 DESC


-- looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vac
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- using cte to perform calculation in previous query
WITH PopvsVac AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vac
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *,
(rolling_total_vac/population)*100 AS vaccinations_percentage
FROM PopvsVac


-- temp table

DROP TABLE IF EXISTS #percent_populate_vac
CREATE TABLE #percent_populate_vac
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_total_vac numeric
)

INSERT INTO #percent_populate_vac
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vac
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (rolling_total_vac/population)*100 AS vaccinations_percentage
FROM #percent_populate_vac


-- creating view to store data for later visualizations

CREATE VIEW vw_percent_populate_vac AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vac
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL