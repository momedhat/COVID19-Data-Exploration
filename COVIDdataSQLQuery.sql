
-- First, we will check all tables structure and columns 
SELECT TOP 5 * 
FROM CovidProject..TotalCases

SELECT TOP 5 * 
FROM CovidProject..TotalVaccinations


-- get the data and columns that we will use 
-- Columns: continent & location & date & total_cases & total_deaths & new_cases
SELECT continent, location, date, total_cases, total_deaths, new_cases
FROM CovidProject..TotalCases
ORDER BY location, date


-- get total deaths in USA 
SELECT location, date, total_deaths
FROM CovidProject..TotalCases
WHERE location LIKE '%states%'
ORDER BY 2


-- looking for total cases vs. population 
SELECT location, date, population, total_cases, (total_cases / population)*100 AS total_cases_persentage
FROM CovidProject..TotalCases
ORDER BY 1,2


-- list the countries by the total cases
SELECT location, max(CAST(total_cases AS int)) AS max_total_cases, ROUND(max(total_cases / population)*100,2) AS total_cases_percentage
FROM CovidProject..TotalCases
WHERE location NOT IN ('World', 'European Union', 'Asia', 'Europe', 'North America', 'South America', 'Africa')
GROUP BY location
ORDER BY 2 DESC,1 


-- showing countries descending by total death
SELECT location, max(CAST(total_deaths AS INt)) AS 'total deaths', ROUND(max(total_deaths / total_cases)*100,2) AS 'deaths percentage of deaths per total cases'
FROM CovidProject..TotalCases
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC,1 


-- let's show it by continents
SELECT continent, max(CAST(total_deaths AS INT)) AS 'total deaths'
FROM CovidProject..TotalCases
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC,1 


-- get the daily total cases
SELECT CAST(date AS date) AS date, SUM(new_cases) AS 'total cases'
FROM CovidProject..TotalCases
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1


-- get the global cases number in the whole world
SELECT SUM(new_cases) AS 'Total Cases', SUM(CAST(new_deaths AS INT)) AS 'Total Deaths', ROUND(( SUM(CAST(new_deaths AS INT))/SUM(new_cases) )*100,2) As 'Death Percentage'
FROM CovidProject..TotalCases
WHERE continent IS NOT NULL


-- get the sum of total cases in the whole world
SELECT MAX(CAST(total_cases AS INT)) AS 'total cases'
FROM CovidProject..TotalCases
WHERE continent IS NOT NULL


-- Showing contintents with the Total death count
SELECT continent, SUM(cast(new_deaths as int)) as HighestDeathCases
FROM CovidProject..TotalCases
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCases desc;


-- showing the total cases vs vaccinations and persentage
SELECT CAST(tc.date AS date) AS Date, tc.location, total_cases AS 'Total Cases',  new_vaccinations AS 'Total Vaccinations', ROUND((CAST(total_vaccinations AS INT) / CAST(total_cases AS INT)*100),2) AS 'Vaccinations Persentage'
FROM CovidProject..TotalCases tc
JOIN CovidProject..TotalVaccinations tv
ON tc.date = tv.date
AND tc.location = tv.location
WHERE tc.continent IS NOT NULL
ORDER BY 1,2


-- Using CTE to perform Calculation on Partition By in previous query to show Percentage of Population that has recieved at least one Covid Vaccine also
WITH PopvsVacc(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS(
SELECT tc.continent, tc.location, tc.date, tc.population, tv.new_vaccinations AS 'New Vaccinations',
SUM(CAST(tv.new_vaccinations AS INT)) OVER (PARTITION BY tc.location) as RollingPeopleVaccinated
From CovidProject..TotalCases tc
Join CovidProject..TotalVaccinations tv
on tc.location = tv.location
and tc.date = tv.date
where tc.continent is not null
)
Select *, ROUND((RollingPeopleVaccinated/Population)*100, 2) AS 'Rolling People Vaccinated vs. population precentage'
From PopvsVacc 


-- Perform the previous query using Temp Table
DROP TABLE IF EXISTS #PopVsVaccPresentage

CREATE TABLE #PopVsVaccPresentage 
(
continent NVARCHAR(225),
location NVARCHAR(225),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PopVsVaccPresentage
SELECT tc.continent, tc.location, tc.date, tc.population, tv.new_vaccinations AS 'New Vaccinations',
SUM(CAST(tv.new_vaccinations AS INT)) OVER (PARTITION BY tc.location) as RollingPeopleVaccinated
From CovidProject..TotalCases tc
Join CovidProject..TotalVaccinations tv
on tc.location = tv.location
and tc.date = tv.date
where tc.continent is not null

SELECT *, ROUND((RollingPeopleVaccinated/Population)*100, 2) AS 'Rolling People Vaccinated vs. population precentage'
FROM #PopVsVaccPresentage


-- Create view to store data for visualizations
CREATE VIEW PopVsVaccPresentage AS
SELECT tc.continent, tc.location, tc.date, tc.population, tv.new_vaccinations, SUM(CAST(tv.new_vaccinations AS INT)) OVER (PARTITION BY tc.location ORDER BY tc.location, tc.Date) as RollingPeopleVaccinated
From CovidProject..TotalCases tc
Join CovidProject..TotalVaccinations tv
	On tc.location = tv.location
	and tc.date = tv.date
WHERE tc.continent is not null
