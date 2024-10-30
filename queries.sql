SELECT
a.actor_id,
CONCAT(a.first_name, ' ', a.last_name) as full_name,
COUNT(f.film_id) AS movies_made
FROM actor a
INNER JOIN
film_actor
ON
a.actor_id = film_actor.actor_id
INNER JOIN film f
ON film_actor.film_id = f.film_id
GROUP BY a.actor_id
ORDER BY movies_made DESC;


SELECT actorid, full_name, 
       COUNT(filmtitle) film_count_peractor
FROM
    (SELECT a.actor_id actorid,
	        a.first_name, 
            a.last_name,
            a.first_name || ' ' || a.last_name AS full_name,
            f.title filmtitle
    FROM    film_actor fa
    JOIN    actor a
    ON      fa.actor_id = a.actor_id
    JOIN    film f
    ON      f.film_id = fa.film_id) t1
GROUP BY 1, 2
ORDER BY 3 DESC;

SELECT
t1.filmlen_groups,
COUNT(t1.filmlen_groups)
FROM
(
    SELECT 
        a.first_name || ' ' || a.last_name AS full_name,
        f.title AS filmtitle,
        f.length,
    CASE
        WHEN f.length <= 60 THEN '1 hour or less'
        WHEN f.length BETWEEN 61 and 120 THEN 'Between 1-2 hours'
        WHEN f.length BETWEEN 121 and 180 THEN 'Between 2-3 hours'
    ELSE
        'More than 3 hours'
    END AS "filmlen_groups"
    FROM actor a
    INNER JOIN
    film_actor
    ON
    a.actor_id = film_actor.actor_id
    INNER JOIN film f
    ON film_actor.film_id = f.film_id
    ORDER BY 2
) t1
GROUP BY filmlen_groups;
    
    







-- Project Queries
-- Question 1
-- Create a query that lists each movie, the film category it is classified in,
-- and the number of times it has been rented out.
SELECT
    t1.title AS "film_title",
    t1.name AS "category_name",
    t2.rental_count
FROM
    (
    SELECT 
       f.film_id,
       f.title,
       c.name
    FROM 
        film f INNER JOIN film_category fc USING (film_id)
    INNER JOIN category c USING (category_id)
    WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
    ) t1
INNER JOIN
    (
    SELECT
        f.film_id,
        COUNT(r.rental_id) as "rental_count"
    FROM
        film f INNER JOIN inventory i USING (film_id)
    INNER JOIN rental r USING (inventory_id)
    GROUP BY 1
    ) t2
USING (film_id)
ORDER BY 2, 1;


-- Question 2
-- Now we need to know how the length of rental duration of these family-friendly movies compares to the duration that all movies are rented for. Can you provide a table with the movie titles and divide them into 4 levels (first_quarter, second_quarter, third_quarter, and final_quarter) based on the quartiles (25%, 50%, 75%) of the average rental duration(in the number of days) for movies across all categories? Make sure to also indicate the category that these family-friendly movies fall into.
-- ** https://knowledge.udacity.com/questions/741914


    SELECT
        f.title,
        c.name,
        f.rental_duration,
        NTILE(4) OVER (ORDER BY rental_duration) AS standard_quartile
    FROM
        film f
        INNER JOIN
        film_category fc USING (film_id)
        INNER JOIN
        category c USING (category_id)
    WHERE
        c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music');

-- Question 2
-- Finally, provide a table with the family-friendly film category,
-- each of the quartiles, and the corresponding count of movies within
-- each combination of film category for each corresponding rental duration category.
WITH quartile_cte AS
(
  SELECT
        f.film_id,
        c.name,
        f.rental_duration,
        NTILE(4) OVER (ORDER BY rental_duration) AS standard_quartile
    FROM
        film f
        INNER JOIN
        film_category fc USING (film_id)
        INNER JOIN
        category c USING (category_id)
    WHERE
        c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
 )
 SELECT
        name,
        standard_quartile,
        COUNT(film_id) AS "count"
 FROM quartile_cte
 GROUP BY
        1, 2
 ORDER BY 1,2;

---Window function option
WITH quartile_cte AS (
    SELECT
        f.film_id,
        c.name,
        f.rental_duration,
        NTILE(4) OVER (ORDER BY rental_duration) AS standard_quartile
    FROM
        film f
        INNER JOIN film_category fc USING (film_id)
        INNER JOIN category c USING (category_id)
    WHERE
        c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
),
count_cte AS (
    SELECT
        name,
        standard_quartile,
        COUNT(*) OVER (PARTITION BY name, standard_quartile) AS count,
        ROW_NUMBER() OVER (PARTITION BY name, standard_quartile ORDER BY film_id) AS rn
    FROM
        quartile_cte
)
SELECT
    name,
    standard_quartile,
    count
FROM
    count_cte
WHERE
    rn = 1
ORDER BY
    name, standard_quartile;
    
-- Set 2 Question 1
SELECT
    DATE_PART('month', r.rental_date) AS Rental_month,
    DATE_PART('year', r.rental_date) AS Rental_year,
    sto.store_id AS store_id,
    COUNT(*) AS Count_rentals
FROM rental r INNER JOIN staff sta USING(staff_id)
INNER JOIN store sto USING(store_id)
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

-- Set 2, Question 2
-- CORRECT Sql syle
-- Annotate that I had to use date manipulation to meet format - pgadmin
WITH highest_spenders AS (
    SELECT customer_id,
           SUM(amount) AS sum_payments
    FROM   payment
    GROUP BY
           customer_id
    ORDER BY
           sum_payments DESC
    LIMIT  10
)
SELECT TO_CHAR(DATE_TRUNC('month', p.payment_date::timestamp)::date + TIME '00:00:00',
               'YYYY-MM-DD"T"HH24:MI:SS.000Z') AS pay_mon,
       CONCAT(c.first_name, ' ', c.last_name) AS fullname,
       COUNT(p.payment_id) AS pay_countpermon,
       SUM(p.amount) AS pay_amount
FROM   payment p
       INNER JOIN customer c USING (customer_id)
WHERE  p.customer_id IN (SELECT customer_id FROM highest_spenders)
AND    DATE_PART('year', p.payment_date) = 2007
GROUP BY
       DATE_TRUNC('month', p.payment_date),
       c.customer_id,
       c.first_name,
       c.last_name
ORDER BY
       fullname,
       pay_mon;
  
-- Set 2, Question 3
-- CORRECT Sql syle
-- Might be able to refactor this
SELECT
    DATE_PART('month', r.rental_date) AS Rental_month,
    DATE_PART('year', r.rental_date) AS Rental_year,
    sto.store_id AS store_id,
    COUNT(*) AS Count_rentals
FROM rental r INNER JOIN staff sta USING(staff_id)
INNER JOIN store sto USING(store_id)
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

-- Set 2, Question 2
-- CORRECT Sql syle
WITH highest_spenders AS (
    SELECT customer_id,
           SUM(amount) AS sum_payments
    FROM   payment
    GROUP BY
           customer_id
    ORDER BY
           sum_payments DESC
    LIMIT  10
),
monthly_amounts AS (
   SELECT TO_CHAR(DATE_TRUNC('month', p.payment_date::timestamp)::date + TIME '00:00:00',
               'YYYY-MM-DD"T"HH24:MI:SS.000Z') AS pay_mon,
   CONCAT(c.first_name, ' ', c.last_name) AS fullname,
       COUNT(p.payment_id) AS pay_countpermon,
       SUM(p.amount) AS pay_amount
FROM   payment p
       INNER JOIN customer c USING (customer_id)
WHERE  p.customer_id IN (SELECT customer_id FROM highest_spenders)
AND    DATE_PART('year', p.payment_date) = 2007
GROUP BY
       DATE_TRUNC('month', p.payment_date),
       c.customer_id,
       c.first_name,
       c.last_name
ORDER BY
       fullname,
       pay_mon
)
SELECT
    pay_mon,
    fullname,
    pay_countpermon,
    pay_amount,
    pay_amount - LAG(pay_amount, 1, pay_amount) OVER (PARTITION BY fullname ORDER BY pay_mon) AS monthly_pay_difference
 FROM
    monthly_amounts
 ORDER BY
        fullname,
        pay_mon;
    