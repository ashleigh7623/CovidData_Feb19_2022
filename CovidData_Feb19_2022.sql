SELECT *
FROM CovidData..coviddeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT *
--FROM CovidData..CovidVaccinations

--Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population 
From CovidData..coviddeaths
WHERE continent is not null
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidData..coviddeaths
WHERE location like '%states%'
and continent is not null
ORDER BY 1,2
--As of Feb 19, 2022 there is a 1.19% chance of death if infected.
--Shows likelihood of dying if you contract covid in the country

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
Select Location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
From CovidData..coviddeaths
WHERE location like '%states%'
and continent is not null
ORDER BY 1,2
--As of Feb 19,2022- 23.5% of US population has been infected with covid

--Looking at Countries with Highest Infection Rate compared to Population
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidData..coviddeaths
WHERE continent is not null
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--Looking at Countries with Highest Death Count per Population
SELECT Location, MAX(cast(total_deaths as INT)) as TotalDeathCount 
FROM CovidData..coviddeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Looking at Continents with Highest Death Count per Population
SELECT continent, MAX(cast(total_deaths as INT)) as TotalDeathCount 
FROM CovidData..coviddeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC
--Notice this doesn't give accurate data as I can quickly see North America only includes US

SELECT location, MAX(cast(total_deaths as INT)) as TotalDeathCount 
FROM CovidData..coviddeaths
WHERE continent is null
and location not like '%income'
GROUP BY location
ORDER BY TotalDeathCount DESC
--Data included locations with lower,middle,high incomes- take out for more accuracy

--GLOBAL NUMBERS
Select date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as INT)) as TotalDeaths, SUM(cast(new_deaths as INT))/SUM(new_cases)*100 as DeathPercentage  --total_cases, population, (total_cases/population)*100 as InfectionRate
From CovidData..coviddeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--TOTAL WORLD WIDE as ONE DATA POINT
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as INT)) as TotalDeaths, SUM(cast(new_deaths as INT))/SUM(new_cases)*100 as DeathPercentage  --total_cases, population, (total_cases/population)*100 as InfectionRate
From CovidData..coviddeaths
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2



--Looking at Total Population vs Vaccinations
SELECT * 
FROM CovidData..CovidDeaths dea 
JOIN CovidData..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
FROM CovidData..CovidDeaths dea 
JOIN CovidData..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Rolling Count of Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidData..CovidDeaths dea 
JOIN CovidData..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidData..CovidDeaths dea 
JOIN CovidData..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentageVaccinated
FROM PopvsVac


-- TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidData..CovidDeaths dea 
JOIN CovidData..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentageVaccinated
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

CREATE View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
, SUM(cast(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidData..CovidDeaths dea 
JOIN CovidData..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT * 
FROM PercentPopulationVaccinated