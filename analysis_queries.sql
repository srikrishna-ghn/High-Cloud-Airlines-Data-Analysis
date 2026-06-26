CREATE DATABASE high_cloud_airlines;
USE high_cloud_airlines;
desc maindata;

-- SECTION 1: DATA PREPARATION & MODELING
-- KPI 1: Calendar Dimension Table

CREATE TABLE calendar (
  datekey DATE,
  year_num INT,
  month_no INT,
  month_fullname VARCHAR(20),
  quarter VARCHAR(2),
  yearmonth VARCHAR(10),
  weekday_no INT,
  weekday_name VARCHAR(20),
  financial_month INT,
  financial_quarter VARCHAR(2)
);

INSERT INTO calendar (
  datekey, year_num, month_no, month_fullname, quarter, yearmonth,
  weekday_no, weekday_name, financial_month, financial_quarter
)
SELECT
    -- Create DATE from Year, Month(#) and Day
    STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d') AS datekey,
    
    Year AS year_num,
    `Month (#)` AS month_no,
    DATE_FORMAT(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d'),
        '%M'
    ) AS month_fullname,
    
    CONCAT('Q', QUARTER(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d')
    )) AS quarter,
    
    DATE_FORMAT(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d'),
        '%Y-%b'
    ) AS yearmonth,
    
    DAYOFWEEK(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d')
    ) AS weekday_no,
    
    DATE_FORMAT(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d'),
        '%W'
    ) AS weekday_name,

    -- FINANCIAL MONTH (FY = April–March)
    CASE 
        WHEN `Month (#)` >= 4 THEN `Month (#)` - 3
        ELSE `Month (#)` + 9
    END AS financial_month,

    -- FINANCIAL QUARTER
    CASE 
        WHEN `Month (#)` BETWEEN 4 AND 6 THEN 'Q1'
        WHEN `Month (#)` BETWEEN 7 AND 9 THEN 'Q2'
        WHEN `Month (#)` BETWEEN 10 AND 12 THEN 'Q3'
        ELSE 'Q4'
    END AS financial_quarter

FROM maindata;
SELECT * FROM calendar;

-- SECTION 2: TIME-BASED ANALYSIS
-- KPI 2: Yearly Load Factor % 

SELECT
    Year,
    concat(round((avg(`# Transported Passengers`) * 1.0 / avg(`# Available Seats`)*100),2),"%") AS Yearly_LoadFactor
FROM maindata
GROUP BY Year
ORDER BY Year;

-- KPI 3: Quarterly Load factor % 

SELECT
    Year,
    QUARTER(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d')
    ) AS Quarter,
    concat(round((avg(`# Transported Passengers`) * 1.0 / avg(`# Available Seats`)*100),2),"%") AS Quarterly_LoadFactor
FROM maindata
GROUP BY 
    Year,
    QUARTER(
        STR_TO_DATE(CONCAT(Year,'-',`Month (#)`,'-',Day), '%Y-%m-%d')
    )
ORDER BY Year, Quarter;

-- KPI 4: Monthly Load factor % 

SELECT
    Year,
    `Month (#)` AS MonthNo,
    concat(round((avg(`# Transported Passengers`) * 1.0 / avg(`# Available Seats`)*100),2),"%") AS Monthly_LoadFactor
FROM maindata
GROUP BY 
    Year,
    `Month (#)`
ORDER BY 
    Year,
    MonthNo;
    
-- KPI 5: Year-over-Year Passenger Growth
SELECT
    Year,
    SUM(`# Transported Passengers`) AS TotalPassengers
FROM maindata
GROUP BY Year
ORDER BY Year;

-- KPI 6: Busiest Travel Month

SELECT
    `Month (#)` AS MonthNo,
    SUM(`# Transported Passengers`) AS TotalPassengers
FROM maindata
GROUP BY `Month (#)`
ORDER BY TotalPassengers DESC;

-- SECTION 3: CARRIER PERFORMANCE ANALYSIS
-- KPI 7: Load Factor by Carrier

SELECT
  `Carrier Name` AS CarrierName,
  ifnull(concat(round(avg(`# Transported Passengers`) / avg(`# Available Seats`)*100,2),"%"),concat(0,"%")) AS LoadFactor,
  SUM(`# Transported Passengers`) AS TotalPassengers,
  SUM(`# Available Seats`) AS TotalSeats
FROM maindata
GROUP BY `Carrier Name`
ORDER BY LoadFactor DESC;

-- KPI 8: Top 10 Carriers by Passenger Volume

SELECT
    `Carrier Name` AS CarrierName,
    SUM(`# Transported Passengers`) AS TotalPassengers
FROM maindata
GROUP BY `Carrier Name`
ORDER BY TotalPassengers DESC
LIMIT 10;

-- KPI 9: Carrier Market Share %

SELECT
    `Carrier Name`,
    ROUND(
        SUM(`# Transported Passengers`) * 100.0 /
        (
            SELECT SUM(`# Transported Passengers`)
            FROM maindata
        ),
        2
    ) AS MarketSharePercent
FROM maindata
GROUP BY `Carrier Name`
ORDER BY MarketSharePercent DESC;

-- KPI 10: Average Passengers per Flight by Carrier

SELECT
    `Carrier Name`,
    ROUND(
        SUM(`# Transported Passengers`) / COUNT(*),
        2
    ) AS AvgPassengersPerFlight
FROM maindata
GROUP BY `Carrier Name`
ORDER BY AvgPassengersPerFlight DESC;

-- KPI 11: Seat Capacity Utilization by Carrier

SELECT
    `Carrier Name`,
    SUM(`# Available Seats`) AS TotalSeats,
    SUM(`# Transported Passengers`) AS TotalPassengers,
    ROUND(
        SUM(`# Transported Passengers`) /
        SUM(`# Available Seats`) * 100,
        2
    ) AS UtilizationPercent
FROM maindata
GROUP BY `Carrier Name`
ORDER BY UtilizationPercent DESC;

-- SECTION 4: ROUTE & NETWORK ANALYSIS
-- KPI 12: Top 5 Routes by Number of Flights

SELECT
  `From - To City` AS Route,
  COUNT(*) AS NumberOfFlights,
  SUM(`# Transported Passengers`) AS Passengers
FROM maindata
GROUP BY `From - To City`
ORDER BY NumberOfFlights DESC
LIMIT 5;

-- KPI 13: Top 10 Routes by Passenger Volume

SELECT
    `From - To City` AS Route,
    SUM(`# Transported Passengers`) AS TotalPassengers
FROM maindata
GROUP BY `From - To City`
ORDER BY TotalPassengers DESC
LIMIT 10;

-- KPI 14: Weekend vs Weekday Load Factor

SELECT
    CASE 
        WHEN DAYNAME(
            STR_TO_DATE(CONCAT(Year,'-', LPAD(`Month (#)`,2,'0'), '-', LPAD(Day,2,'0')), '%Y-%m-%d')
        ) IN ('Saturday','Sunday') 
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,

    SUM(`# Transported Passengers`) AS TotalPassengers,
    SUM(`# Available Seats`) AS TotalSeats,
    concat(round(avg(`# Transported Passengers`)/ NULLIF(avg(`# Available Seats`),0),2)*100,"%") AS LoadFactor

FROM maindata
WHERE STR_TO_DATE(CONCAT(Year,'-', LPAD(`Month (#)`,2,'0'), '-', LPAD(Day,2,'0')), '%Y-%m-%d') IS NOT NULL
GROUP BY DayType;

-- KPI 15: Flights by Distance Group

SELECT
    `%distance group id` AS DistanceGroup,
    COUNT(*) AS NoOfFlights
FROM maindata
GROUP BY `%distance group id`
ORDER BY `%distance group id`;

-- SECTION 5: AIRPORT ANALYSIS

-- KPI 16: Top 10 Origin Airports

SELECT
    `Origin Airport Code`,
    COUNT(*) AS TotalFlights
FROM maindata
GROUP BY `Origin Airport Code`
ORDER BY TotalFlights DESC
LIMIT 10;

-- KPI 17: Top 10 Destination Airports

SELECT
    `Destination Airport Code`,
    COUNT(*) AS TotalFlights
FROM maindata
GROUP BY `Destination Airport Code`
ORDER BY TotalFlights DESC
LIMIT 10;

    
								