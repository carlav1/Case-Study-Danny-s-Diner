-- upload schema
use schema
til_playground.cs1_dannys_diner;

-- Question 1: What is the total amount each customer spent at the restaurant?

select
    a.customer_id as customer_id,
    sum(price) as total_spent
from sales as a 
inner join menu as b 
    on a.product_id = b.product_id
group by a.customer_id;


--Question 2: How many days has each customer visited the restaurant?

select 
    customer_id,
    count(distinct order_date) as total_visit_days
from sales
group by customer_id;

--Question 3: What was the first item from the menu purchased by each customer?

select 
    customer_id,
    product_name
from (select 
    customer_id,
    dense_rank() over (partition by customer_id order by order_date asc) as order_rank,
    order_date,
    product_name
from sales as a
inner join menu as b
    on a.product_id = b.product_id) as rank_table 
where order_rank = 1;

-- Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?

select
    product_name,
    count(*) number_of_sales
from sales as a
inner join menu as b 
    on a.product_id = b.product_id
group by product_name
order by number_of_sales desc;

--most purchased item is ramen

select 
    customer_id,
    count(*) as total_count
from sales
where product_id = 3
group by customer_id;

--Question 5: Which item was the most popular for each customer?

select 
    customer_id,
    product_name,
    order_count
from (select
    customer_id,
    product_name,
    dense_rank() over (partition by customer_id order by count(*) desc) as item_rank,
    count(*) as order_count
from sales as a
inner join menu as b 
    on a.product_id = b.product_id
group by product_name, customer_id)
where item_rank = 1;

--Question 6: Which item was purchased first by the customer after they became a member?

with cte as (
select 
    *,
    dateadd(day, 1, join_date)::date as new_date
from members
)

select 
    customer_id,
    product_name
from (select 
    a.customer_id,
    order_date,
    product_name,
    row_number() over (partition by a.customer_id order by order_date asc) as rank_num
from sales as a 
inner join menu as b 
    on a.product_id = b.product_id
inner join cte as c on 
c.customer_id = a.customer_id
where order_date >= new_date) as rank_table 
where rank_num = 1;

--Question 7: Which item was purchased just before the customer became a member?

select 
    customer_id,
    product_name
from (select 
    a.customer_id,
    order_date,
    product_name,
    join_date,
    row_number() over (partition by a.customer_id order by order_date desc) as rank_num
from sales as a 
inner join menu as b 
    on a.product_id = b.product_id
inner join members as c 
    on c.customer_id = a.customer_id
where order_date < join_date) as rank_table
where rank_num =1;

--Question 8: What is the total items and amount spent for each member before they became a member?

select 
    a.customer_id,
    count(a.product_id) as total_items,
    sum(price) as total_amount
from sales as a 
inner join menu as b 
    on a.product_id = b.product_id
inner join members as c 
    on c.customer_id = a.customer_id
where order_date < join_date
group by a.customer_id;

--Question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select 
    customer_id,
    sum(new_price) as new_price
from (select
    customer_id,
    product_name,
    price,
    case 
    when product_name = 'curry' or product_name = 'ramen' then price * 10
    else price * 20 end as new_price
from sales as a 
inner join menu as b 
    on a.product_id = b.product_id) as case_table
group by customer_id;

--Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select 
    c.customer_id as member_customer,
    sum(case 
    when order_date between join_date and dateadd(day, 6, join_date)::date then price * 20
    when b.product_name = 'sushi' then price * 20
    else price * 10 end) as new_total 
from sales as a 
inner join menu as b 
    on a.product_id = b.product_id
inner join members as c
    on c.customer_id = a.customer_id
where a.order_date <= '2021-01-31'
group by c.customer_id;

-- BONUS: Join All The Things

with cte as 
(
select 
    distinct customer_id as cust_id,
    case
    when customer_id not in (select distinct customer_id from members) then 'N'
    else 'Y' end as member
from sales
)
select 
    a.customer_id,
    order_date,
    product_name,
    price,
    member
from sales as a
inner join menu as b 
    on a.product_id = b.product_id
inner join cte as c
    on c.cust_id = a.customer_id;