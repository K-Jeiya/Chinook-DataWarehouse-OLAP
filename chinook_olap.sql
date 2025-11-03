use chinook_olap;

-- ************Step 1: Modelling Dimensions
-- 1. Customer_Dim
CREATE TABLE Customer_Dim (
CustomerID int primary key,
FirstName varchar(30),
LastName varchar(30),
Company varchar(50),Address varchar(100),
City varchar(50),
State varchar(40),
Country varchar(40),
PostalCode varchar(30),
Phone varchar(30),
Fax varchar(30),
Email varchar(50),
CreateDate datetime,
UpdateData datetime
);

-- Customer_Dim :
INSERT INTO chinook_olap.Customer_Dim
(CustomerID, FirstName, LastName, Company, Address, City, State, Country, PostalCode, Phone, Fax, Email, CreateDate, UpdateData)
SELECT CustomerID, FirstName, LastName, Company, Address, City, State, Country, PostalCode, Phone, Fax, Email, NOW(), NOW()
FROM chinook_oltp.customer;

SELECT 'Customer_Dim' AS t, COUNT(*) FROM chinook_olap.Customer_Dim;


-- 2. Track_Dim:
CREATE TABLE Track_Dim(
TrackID int primary key,
TrackName varchar(225),
AlbumTitle varchar(200),
ArtistName varchar(100),
GenreName varchar(100),
Composer varchar(225),
Milliseconds int,
Bytes int,
UnitPrice decimal(10,3),
CreateDate datetime,
UpdateDate datetime
);

-- Track_Dim:
INSERT INTO chinook_olap.Track_Dim
(TrackID, TrackName, AlbumTitle, ArtistName, GenreName, Composer, Milliseconds, Bytes, UnitPrice, CreateDate, UpdateDate)
SELECT t.TrackId, t.Name, a.Title, ar.Name, g.Name, t.Composer, t.Milliseconds, t.Bytes, t.UnitPrice, NOW(), NOW()
FROM chinook_oltp.track t
JOIN chinook_oltp.album a on t.AlbumId = a.AlbumId
JOIN chinook_oltp.artist ar on a.ArtistId = ar.ArtistId
Join chinook_oltp.genre g on t.GenreId = g.GenreId;

SELECT 'Track_Dim' AS t, COUNT(*) FROM chinook_olap.Track_Dim;


-- 3.   Date_Dim:
CREATE TABLE Date_Dim(
date_id int primary key,
date date,
year int,
month varchar(10),
month_of_year int,
day_of_month int ,
day varchar(10),
day_of_week int,
weekend varchar(10),
day_of_year int,
week_of_year int,
quarter int,
previous_day date,
next_day date
);

CALL chinook_olap.extend_dim_date('2009-01-01','2013-12-31');
SELECT 'Date_Dim' as t, COUNT(*) FROM chinook_olap.Date_Dim;

-- ******Step 2: Creating the Fact Table (Invoice_Fact)  
CREATE TABLE chinook_olap.Invoice_Fact ( 
InvoiceID     INT NOT NULL,
CustomerID    INT NOT NULL,
TrackID       INT NOT NULL,
SaleDateID    INT NOT NULL,
TotalQuantity INT,
TotalAmount   DECIMAL(10,2),
PRIMARY KEY (InvoiceID, TrackID),
FOREIGN KEY (CustomerID) REFERENCES Customer_Dim(CustomerID),
FOREIGN KEY (TrackID)    REFERENCES Track_Dim(TrackID),
FOREIGN KEY (SaleDateID) REFERENCES Date_Dim(date_id)
);

-- Load Data 
TRUNCATE TABLE chinook_olap.Invoice_Fact;
INSERT INTO chinook_olap.Invoice_Fact(
InvoiceID, CustomerID, TrackID, SaleDateID, TotalQuantity, TotalAmount)
SELECT il.InvoiceId, i.CustomerId, il.TrackId, d.date_id, il.Quantity, il.UnitPrice * il.Quantity
FROM chinook_oltp.Invoice i
JOIN chinook_oltp.InvoiceLine il on i.InvoiceId = il.InvoiceId
JOIN chinook_olap.Date_Dim d on DATE(i.InvoiceDate) = d.date;

SELECT 'Invoice_Fact' AS t, COUNT(*) FROM chinook_olap.Invoice_Fact;


-- ********** Step 3: Creating Data Mart for Business Intelligence Team
DROP VIEW IF EXISTS chinook_olap.Chinook_Datamart;
CREATE VIEW chinook_olap.Chinook_Datamart AS
SELECT f.InvoiceID, f.CustomerID as FactCustomerID, f.TrackID, f.SaleDateID, f.TotalQuantity, f.TotalAmount, c.FirstName, c.LastName, c.City, c.Country, 
t.TrackName, t.AlbumTitle, t.ArtistName, t.GenreName, d.date, d.year, d.month, d.quarter
FROM chinook_olap.Invoice_Fact f
LEFT JOIN chinook_olap.Customer_Dim c on f.CustomerID = c.CustomerID
LEFT JOIN chinook_olap.Track_Dim    t on f.TrackID    = t.TrackID
LEFT JOIN chinook_olap.Date_Dim     d on f.SaleDateID = d.date_id;

SELECT * FROM chinook_olap.Chinook_Datamart LIMIT 10;








