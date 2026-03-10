-- ============================================================
--  CHINOOK DATABASE — WEEK 2 SQL ASSIGNMENT
--  Author: Ekene Ozonuwe
--  Database: Chinook (SQLite)
-- ============================================================


-- Q1. Return the CustomerID, first name and last name of all customers.

SELECT CustomerID, FirstName, LastName
FROM customers;


-- Q2. Find out when each employee was hired.

SELECT EmployeeId, FirstName, LastName, HireDate
FROM employees;


-- Q3. Return all employee information.

SELECT *
FROM employees;


-- Q4. List album titles and the corresponding artist names.
--     FIX: Original returned ArtistId (a number). Joined to artists table
--          to return the actual artist name as the question requires.

SELECT
    albums.Title      AS album_title,
    artists.Name      AS artist_name
FROM albums
JOIN artists ON albums.ArtistId = artists.ArtistId
ORDER BY artists.Name;


-- Q5. Return all customers who live in Germany.
--     FIX: Changed "Germany" (double quotes) to 'Germany' (single quotes).
--          Double quotes work in SQLite but fail in PostgreSQL / Snowflake.

SELECT *
FROM customers
WHERE Country = 'Germany';


-- Q6. Return all customers who don't live in Germany.

SELECT *
FROM customers
WHERE Country != 'Germany';


-- Q7. Return all invoices for USA purchases with a total greater than $10.
--     FIX 1: Added missing BillingCountry = 'USA' filter (was omitted).
--     FIX 2: Removed quotes around 10 — totals are numeric, not strings.

SELECT *
FROM invoices
WHERE BillingCountry = 'USA'
  AND Total > 10;


-- Q8. Return all Sales Support Agents hired on or after 3 May 2003 in Calgary.

SELECT *
FROM employees
WHERE Title    = 'Sales Support Agent'
  AND HireDate >= '2003-05-03'
  AND City     = 'Calgary';


-- Q9. Display the number of tracks under each media type.
--     UPGRADE: Added alias 'track_count' for readability.

SELECT
    media_types.MediaTypeId,
    media_types.Name                AS media_type,
    COUNT(tracks.TrackId)           AS track_count
FROM media_types
JOIN tracks ON media_types.MediaTypeId = tracks.MediaTypeId
GROUP BY media_types.MediaTypeId, media_types.Name
ORDER BY track_count DESC;


-- Q10. Display the first 15 tracks with the highest unit price.
--      UPGRADE: Added Name alias for clarity.

SELECT
    TrackId,
    Name        AS track_name,
    UnitPrice
FROM tracks
ORDER BY UnitPrice DESC
LIMIT 15;
