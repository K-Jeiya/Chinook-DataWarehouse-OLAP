DELIMITER //
DROP PROCEDURE IF EXISTS chinook_olap.extend_dim_date //
CREATE PROCEDURE chinook_olap.extend_dim_date(IN start_date DATE, IN end_date DATE)
BEGIN

	-- Credit to http://www.dwhworld.com/2010/08/date-dimension-sql-scripts-mysql/
	-- Small-numbers table
    
    declare table_check VARCHAR(100);
    declare table_end_date DATE;
    
    set table_check := (SELECT table_name FROM information_schema.tables WHERE table_schema = 'classicmodels_olap' AND table_name = 'date_dim' LIMIT 1) ;
    
    if NOT(table_check='date_dim') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Date_DIM Does not exist, Initiate Create Date Dim First';  End IF;
    
    set table_end_date := ( select max(date) max_date from classicmodels_olap.date_dim) ;
    
    if (end_date<=table_end_date) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data for requested Data Parameters already exist';  End IF;

	DROP TABLE IF EXISTS classicmodels_olap.numbers_small;
	CREATE TABLE classicmodels_olap.numbers_small (number INT);
	INSERT INTO classicmodels_olap.numbers_small VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

	-- Main-numbers table
	DROP TABLE IF EXISTS classicmodels_olap.numbers;
	CREATE TABLE classicmodels_olap.numbers (number BIGINT);
	INSERT INTO classicmodels_olap.numbers
	SELECT thousands.number * 1000 + hundreds.number * 100 + tens.number * 10 + ones.number
	FROM classicmodels_olap.numbers_small thousands, classicmodels_olap.numbers_small hundreds, classicmodels_olap.numbers_small tens, classicmodels_olap.numbers_small ones
	LIMIT 1000000;

	-- First populate with ids and Date
	-- Change year start and end to match your needs. The above sql creates records for year 2010.
	INSERT INTO classicmodels_olap.date_dim (date_id, date)
	SELECT year(DATE_ADD( start_date, INTERVAL number DAY ))*10000+
	month(DATE_ADD( start_date, INTERVAL number DAY ))*100+
	day(DATE_ADD( start_date, INTERVAL number DAY ))date_id 
    ,DATE_ADD( start_date, INTERVAL number DAY )
	FROM classicmodels_olap.numbers
	WHERE DATE_ADD( start_date, INTERVAL number DAY ) BETWEEN start_date AND end_date
	ORDER BY number;
    
	SET SQL_SAFE_UPDATES = 0;
	
    -- Update other columns based on the date.
    UPDATE classicmodels_olap.date_dim SET
	year            = DATE_FORMAT( date, "%Y" ),
	month           = DATE_FORMAT( date, "%M"),
	month_of_year   = DATE_FORMAT( date, "%m"),
	day_of_month    = DATE_FORMAT( date, "%d" ),
	day             = DATE_FORMAT( date, "%W" ),
	day_of_week     = DAYOFWEEK(date),
	weekend         = IF( DATE_FORMAT( date, "%W" ) IN ('Saturday','Sunday'), 'Weekend', 'Weekday'),
	day_of_year     = DATE_FORMAT( date, "%j" ),
	week_of_year    = DATE_FORMAT( date, "%V" ),
	quarter         = QUARTER(date),
	previous_day    = DATE_ADD(date, INTERVAL -1 DAY),
	next_day        = DATE_ADD(date, INTERVAL 1 DAY);
    
    select 'ROWS INSERTED' SUCCESS;

	drop table if exists classicmodels_olap.numbers;
	drop table if exists classicmodels_olap.numbers_small;
    
END //
DELIMITER ;
