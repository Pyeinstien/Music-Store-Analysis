-- EASY QUESTION SET:

-- 1) Who is the senior most employee based on Job title ?

SELECT FIRST_NAME,LAST_NAME FROM EMPLOYEE WHERE TITLE = 'Senior General Manager';
                            -- or
SELECT FIRST_NAME,LAST_NAME FROM EMPLOYEE ORDER BY LEVELS DESC LIMIT 1;


-- 2) Which country has the most invoices?

SELECT BILLING_COUNTRY,COUNT(BILLING_COUNTRY) AS NO_OF_INVOICE 
FROM INVOICE GROUP BY BILLING_COUNTRY ORDER BY NO_OF_INVOICE DESC;


-- 3) What are the top 3 invoices according to total?

SELECT TOTAL FROM INVOICE ORDER BY TOTAL DESC LIMIT 3;


-- 4) Which city has the best customers? Return city name and sum of all invoice totals of that city.

SELECT SUM(TOTAL) AS TOTAL_INVOICE,BILLING_CITY FROM INVOICE GROUP BY BILLING_CITY ORDER BY TOTAL_INVOICE DESC;



-- 5) Who is the best customer? The customer who spent most money is the best customer.

SELECT CUSTOMER.CUSTOMER_ID,CUSTOMER.FIRST_NAME, CUSTOMER.LAST_NAME, SUM(INVOICE.TOTAL) AS TOTAL_INVOICE
FROM CUSTOMER INNER JOIN INVOICE
ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID
GROUP BY CUSTOMER.CUSTOMER_ID
ORDER BY TOTAL_INVOICE DESC LIMIT 1;

-- x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-
-- MEDIUM QUESTION SET:

-- 1) Return email, first name, last name of all rock music listeners. List should be in alphabeticall order by mail.

SELECT DISTINCT(CUSTOMER.FIRST_NAME), CUSTOMER.LAST_NAME, CUSTOMER.EMAIL, GENRE.NAME
FROM ((((CUSTOMER INNER JOIN INVOICE ON CUSTOMER.CUSTOMER_ID = INVOICE.CUSTOMER_ID)
	  INNER JOIN INVOICE_LINE ON INVOICE.INVOICE_ID = INVOICE_LINE.INVOICE_ID)
	  INNER JOIN TRACK ON INVOICE_LINE.TRACK_ID = TRACK.TRACK_ID)
	  INNER JOIN GENRE ON TRACK.GENRE_ID = GENRE.GENRE_ID)
WHERE GENRE.NAME = 'Rock'
ORDER BY CUSTOMER.EMAIL;


-- 2) Return the top 10 artists who has written most rock music.

SELECT ARTIST.ARTIST_ID,ARTIST.NAME,COUNT(ARTIST.ARTIST_ID) AS TOTAL_TRACKS
FROM (((ARTIST INNER JOIN ALBUM ON ARTIST.ARTIST_ID = ALBUM.ARTIST_ID)
	INNER JOIN TRACK ON ALBUM.ALBUM_ID = TRACK.ALBUM_ID)
	INNER JOIN GENRE ON TRACK.GENRE_ID = GENRE.GENRE_ID)
WHERE GENRE.NAME = 'Rock'
GROUP BY ARTIST.ARTIST_ID
ORDER BY TOTAL_TRACKS DESC LIMIT 10;


-- 3) Return all the track names that have a song length greater than the average song length.

SELECT NAME,MILLISECONDS FROM TRACK WHERE MILLISECONDS > (SELECT AVG(MILLISECONDS) FROM TRACK) 
ORDER BY MILLISECONDS DESC;

-- x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-
-- HARD QUESTIONS SET:

-- 1) Find how much amount spent by each customer on artists.

WITH BEST_SELLING_ARTIST AS (
	SELECT ARTIST.ARTIST_ID, ARTIST.NAME, SUM(INVOICE_LINE.UNIT_PRICE*INVOICE_LINE.QUANTITY) AS TOTAL_COST
	FROM (((ARTIST INNER JOIN ALBUM ON ARTIST.ARTIST_ID = ALBUM.ARTIST_ID)
	INNER JOIN TRACK ON ALBUM.ALBUM_ID = TRACK.ALBUM_ID)
	INNER JOIN INVOICE_LINE ON TRACK.TRACK_ID = INVOICE_LINE.TRACK_ID)
	GROUP BY ARTIST.ARTIST_ID
	ORDER BY TOTAL_COST DESC
	LIMIT 1
)
SELECT C.CUSTOMER_ID, C.FIRST_NAME, C.LAST_NAME, BSA.NAME, SUM(IL.UNIT_PRICE*IL.QUANTITY) AS TOTAL_AMOUNT
FROM (((((CUSTOMER C INNER JOIN INVOICE I ON C.CUSTOMER_ID = I.CUSTOMER_ID)
	INNER JOIN INVOICE_LINE IL ON IL.INVOICE_ID = I.INVOICE_ID)
	INNER JOIN TRACK T ON T.TRACK_ID = IL.TRACK_ID)
	INNER JOIN ALBUM A ON A.ALBUM_ID = T.ALBUM_ID)
	INNER JOIN BEST_SELLING_ARTIST BSA ON BSA.ARTIST_ID = A.ARTIST_ID)
GROUP BY 1,2,3,4
ORDER BY TOTAL_AMOUNT DESC;


-- 2) Return the most popular music genre for each country. Popular genre is determined by higest amount of purchases.

WITH BEST_GENRE AS (
	SELECT G.GENRE_ID, G.NAME, I.BILLING_COUNTRY, COUNT(IL.QUANTITY) AS TOTAL_PURCHASES,
	ROW_NUMBER() OVER (PARTITION BY I.BILLING_COUNTRY ORDER BY COUNT(IL.QUANTITY) DESC) AS ROW_NO
	FROM (((INVOICE_LINE IL INNER JOIN INVOICE I ON I.INVOICE_ID = IL.INVOICE_ID)
	INNER JOIN TRACK T ON T.TRACK_ID = IL.TRACK_ID)
	INNER JOIN GENRE G ON G.GENRE_ID = T.GENRE_ID)
	GROUP BY G.GENRE_ID, G.NAME,I.BILLING_COUNTRY
	ORDER BY I.BILLING_COUNTRY ASC, TOTAL_PURCHASES DESC
)
SELECT * FROM BEST_GENRE WHERE ROW_NO = 1;
--            											or
WITH RECURSIVE BEST_GENRE AS (
	SELECT G.GENRE_ID, G.NAME, I.BILLING_COUNTRY AS COUNTRY, COUNT(*) AS TOTAL_PURCHASES_PER_GENRE
	FROM (((INVOICE_LINE IL INNER JOIN INVOICE I ON I.INVOICE_ID = IL.INVOICE_ID)
	INNER JOIN TRACK T ON T.TRACK_ID = IL.TRACK_ID)
	INNER JOIN GENRE G ON G.GENRE_ID = T.GENRE_ID)
	GROUP BY G.GENRE_ID, G.NAME,I.BILLING_COUNTRY
	ORDER BY I.BILLING_COUNTRY
),
MAX_GENRE_PURCHASED AS (SELECT MAX(TOTAL_PURCHASES_PER_GENRE) AS TOTAL_PURCHASES, COUNTRY
FROM BEST_GENRE GROUP BY 2 ORDER BY 2)
SELECT BEST_GENRE.* FROM BEST_GENRE INNER JOIN MAX_GENRE_PURCHASED ON MAX_GENRE_PURCHASED.COUNTRY = BEST_GENRE.COUNTRY
WHERE BEST_GENRE.TOTAL_PURCHASES_PER_GENRE = MAX_GENRE_PURCHASED.TOTAL_PURCHASES;


-- 3) Determine the customer that has spent the most amount on music for each country along with total amount spent.

WITH RECURSIVE BEST_CUSTOMER AS (
	SELECT C.CUSTOMER_ID, C.FIRST_NAME, C.LAST_NAME, I.BILLING_COUNTRY AS COUNTRY, SUM(I.TOTAL) AS TOTAL_SPENT
	FROM CUSTOMER C INNER JOIN INVOICE I ON I.CUSTOMER_ID = C.CUSTOMER_ID
	GROUP BY 1,2,3,4
	ORDER BY 1,5 DESC
), MAX_SPENT AS (SELECT MAX(TOTAL_SPENT) AS SPENT_BY_CUSTOMER, COUNTRY 
				 FROM BEST_CUSTOMER GROUP BY COUNTRY)
SELECT BEST_CUSTOMER.* FROM BEST_CUSTOMER INNER JOIN MAX_SPENT
ON MAX_SPENT.COUNTRY = BEST_CUSTOMER.COUNTRY
WHERE MAX_SPENT.SPENT_BY_CUSTOMER = BEST_CUSTOMER.TOTAL_SPENT
ORDER BY COUNTRY;
-- 													 		OR
WITH BEST_CUSTOMER AS (
	SELECT C.CUSTOMER_ID, C.FIRST_NAME, C.LAST_NAME, I.BILLING_COUNTRY AS COUNTRY, SUM(I.TOTAL) AS TOTAL_SPENT,
	ROW_NUMBER() OVER (PARTITION BY I.BILLING_COUNTRY ORDER BY SUM(I.TOTAL) DESC) AS ROW_NO
	FROM CUSTOMER C INNER JOIN INVOICE I ON I.CUSTOMER_ID = C.CUSTOMER_ID
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC,5 DESC
)
SELECT * FROM BEST_CUSTOMER WHERE ROW_NO = 1;
-- x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-