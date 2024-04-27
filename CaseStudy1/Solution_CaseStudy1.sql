/* --------------------
Case Study #1 - Danny's Diner - Questions
   --------------------*/
Select * from [dannys_diner].[members];
Select * from [dannys_diner].[menu];
Select * from [dannys_diner].[sales];

-- 1. What is the total amount each customer spent at the restaurant?
/*
SELECT A.*, B.*
FROM [DANNYS_DINER].[SALES] A
INNER JOIN [DANNYS_DINER].[MENU] B
ON A.PRODUCT_ID=B.PRODUCT_ID
*/

SELECT A.CUSTOMER_ID AS CUSTOMER
	,SUM(B.PRICE) AS TOTAL_AMOUNT 
FROM [DANNYS_DINER].[SALES] A
INNER JOIN [DANNYS_DINER].[MENU] B
ON A.PRODUCT_ID=B.PRODUCT_ID
GROUP BY A.CUSTOMER_ID

-- 2. How many days has each customer visited the restaurant?
/*
Select * from [DANNYS_DINER].[SALES]
*/

SELECT CUSTOMER_ID AS CUSTOMER
	, COUNT(DISTINCT ORDER_DATE) AS DAYS_VISITED
FROM [DANNYS_DINER].[SALES]
GROUP BY CUSTOMER_ID

-- 3. What was the first item from the menu purchased by each customer?
/*
SELECT * FROM [DANNYS_DINER].[SALES];
*/

WITH DATA AS(SELECT CUSTOMER_ID AS CUSTOMER
	, ORDER_DATE
	, PRODUCT_ID AS FIRST_ITEM
	, ROW_NUMBER() OVER(PARTITION BY CUSTOMER_ID, ORDER_DATE ORDER BY ORDER_DATE) AS ROW
FROM [DANNYS_DINER].[SALES]
)
SELECT * FROM DATA
WHERE ROW=1


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT B.PRODUCT_NAME AS [MENU ITEM]
	,COUNT(A.PRODUCT_ID) AS [TIMES PURCHASED]
FROM [DANNYS_DINER].[SALES] A
JOIN [DANNYS_DINER].[MENU] B
ON A.PRODUCT_ID = B.PRODUCT_ID
GROUP BY B.PRODUCT_NAME
ORDER BY 2 DESC


-- 5. Which item was the most popular for each customer?
WITH DATA AS (SELECT A.CUSTOMER_ID AS CUSTOMER
	,B.PRODUCT_NAME AS [MENU ITEM]
	,COUNT(A.PRODUCT_ID) AS [TIMES PURCHASED]
	,RANK() OVER(PARTITION BY CUSTOMER_ID ORDER BY COUNT(A.PRODUCT_ID) DESC) AS RNK
FROM [DANNYS_DINER].[SALES] A
JOIN [DANNYS_DINER].[MENU] B
ON A.PRODUCT_ID = B.PRODUCT_ID
GROUP BY A.CUSTOMER_ID,B.PRODUCT_NAME
)
SELECT * 
FROM DATA
WHERE RNK=1

-- 6. Which item was purchased first by the customer after they became a member?
WITH DATA AS(SELECT A.CUSTOMER_ID AS CUSTOMER
	, C.PRODUCT_NAME
	, RANK() OVER(PARTITION BY B.JOIN_DATE ORDER BY A.ORDER_DATE) RNK
FROM [DANNYS_DINER].[SALES] A
JOIN [DANNYS_DINER].[MEMBERS] B
ON A.CUSTOMER_ID = B.CUSTOMER_ID
AND A.ORDER_DATE>=B.JOIN_DATE
JOIN [DANNYS_DINER].[MENU] C
ON A.PRODUCT_ID=C.PRODUCT_ID
)
SELECT * 
FROM DATA 
WHERE RNK=1

-- 7. Which item was purchased just before the customer became a member?
WITH DATA AS(SELECT A.CUSTOMER_ID AS CUSTOMER
	,C.PRODUCT_NAME AS ITEM
	,COALESCE(DATEDIFF(DAY,A.ORDER_DATE,B.JOIN_DATE),-1) DATE_DIFF
	, RANK() OVER(PARTITION BY B.JOIN_DATE ORDER BY COALESCE(DATEDIFF(DAY,A.ORDER_DATE,B.JOIN_DATE),-1) DESC) RNK
FROM [DANNYS_DINER].[SALES] A
LEFT JOIN [DANNYS_DINER].[MEMBERS] B
ON A.CUSTOMER_ID = B.CUSTOMER_ID
JOIN [DANNYS_DINER].[MENU] C
ON A.PRODUCT_ID=C.PRODUCT_ID
WHERE COALESCE(DATEDIFF(DAY,A.ORDER_DATE,B.JOIN_DATE),-1)<0
--ORDER BY 1,2 DESC
)
SELECT *
FROM DATA 
WHERE RNK=1
Order by 1


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT A.CUSTOMER_ID AS CUSTOMER
	, COUNT(B.PRODUCT_ID) AS [TORAL ITEMS]
	, SUM(B.PRICE) AS [AMOUNT SPNET]
FROM [DANNYS_DINER].[SALES] A
JOIN [DANNYS_DINER].[MENU] B
ON A.PRODUCT_ID=B.PRODUCT_ID
INNER JOIN  [DANNYS_DINER].[MEMBERS] C
ON A.CUSTOMER_ID=C.CUSTOMER_ID
AND A.ORDER_DATE<C.JOIN_DATE
GROUP BY A.CUSTOMER_ID
ORDER BY 1

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with data as (Select A.customer_id as customer
	, B.price
	,case when B.product_name='sushi' then 2 else 1 end as multiplier
From [dannys_diner].[sales] A
Join [dannys_diner].[menu] B
on a.product_id = b.product_id
)
Select customer
	,	sum(price*multiplier) as points
From data 
Group by customer
Order by 1

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?
With data as(Select A.customer_id as customer
	, A.order_date
	, B.product_name
	, B.price
	, DATEDIFF(DAY, C.join_date, A.order_date) as date_diff
	, case when DATEDIFF(DAY, C.join_date, A.order_date)<=7 then 2 else case when B.product_name='sushi' then 2 else 1 end end as multiplier
From [dannys_diner].[sales] A
Join [dannys_diner].[menu] B
on a.product_id = b.product_id
Join [dannys_diner].[members] C
on A.customer_id=C.customer_id 
and A.order_date>=C.join_date
)
Select customer
	,sum(price*multiplier) as points
from data 
where month(order_date)=1 
Group by customer
Order by customer
