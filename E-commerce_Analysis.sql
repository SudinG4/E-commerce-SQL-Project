
-- Creating the Database for our table
Create Database user_events;

-- Inspecting the first 10 rows of the table
Select * 
From user_events
limit 10;

-- Checking the type of each column
Show columns from user_events;

-- Checking the entries in the 'amount' column.
Select  
	amount,
	Case 
		when amount is null then 'null'
		when trim(amount) = '' Then 'space'
		when amount = '' then 'empty'
		else 'has value'
	end as amount_status
From user_events
Limit 20;

-- Updating the amount column having non-value entries to null
Update user_events
set amount = Nullif(trim(amount), '');

-- Inspecting after the change
Select * 
From user_events
limit 10;


-- Changing the column's type to our need
Alter Table user_events
	Modify event_id INT,
    MOdify user_id INT,
    modify event_type varchar(50),
    modify event_date date,
    modify product_id INt,
    modify amount Decimal(10,2),
    modify traffic_source Varchar(50);
    
-- Checking if the execution worked
Select * 
From user_events
limit 10;


-- Number of traffic through stage 1 to stage 5. From viewing to purahasing.
-- How many unique customers reached each stage of the purchase journey from viewing a product to completing a purchase in the last 30 days?

WITH funnel_sales As(
	Select
		Count(Distinct Case When event_type = 'page_view' Then user_id End ) as stage1_view,
		Count(Distinct Case When event_type = 'add_to_cart' Then user_id End ) as stage2_cart,
		Count(Distinct Case When event_type = 'checkout_start' Then user_id End ) as stage3_checkout,
		Count(Distinct Case When event_type = 'payment_info' Then user_id End ) as stage4_payment,
		Count(Distinct Case When event_type = 'purchase' Then user_id End ) as stage5_purchase
    
	From user_events
    Where event_date >= (Select Date_sub(max(event_date), interval 30 day) from user_events)
)
Select * from funnel_sales;

-- Count of total customers in each stage of purchase, from viewing the product to purchasing the product
-- At which stage in the funnel are we losing the most customers, and what's our overall view-to-purchase conversion rate?

WITH funnel_sales As(
	Select
		Count(Distinct Case When event_type = 'page_view' Then user_id End ) as stage1_view,
		Count(Distinct Case When event_type = 'add_to_cart' Then user_id End ) as stage2_cart,
		Count(Distinct Case When event_type = 'checkout_start' Then user_id End ) as stage3_checkout,
		Count(Distinct Case When event_type = 'payment_info' Then user_id End ) as stage4_payment,
		Count(Distinct Case When event_type = 'purchase' Then user_id End ) as stage5_purchase
    
	From user_events
    Where event_date >= (Select Date_sub(max(event_date), interval 30 day) from user_events)
)
Select 
	stage1_view,
	stage2_cart,
	ROund(stage2_cart * 100 / stage1_view) As view_to_cart_rate,
	stage3_checkout,
	ROund(stage3_checkout * 100 / stage2_cart) As cart_to_checkout_rate,
	stage4_payment,
	ROund(stage4_payment * 100 / stage3_checkout) As checkout_to_payment_rate,
	stage5_purchase,
	ROund(stage5_purchase * 100 / stage4_payment) As payment_purchase_rate,

	ROund(stage5_purchase * 100 / stage1_view) As overall_conversion

from funnel_sales;



-- Now lets see the funnel for each category and the total customer each traffic_source bring in on different stages.

-- Which traffic source from organic, paid, social brings in the most customers, and which one converts them most effectively once they arrive?

WITH source_funnel As(
	Select
    traffic_source,
		Count(Distinct Case When event_type = 'page_view' Then user_id End ) as views,
		Count(Distinct Case When event_type = 'add_to_cart' Then user_id End ) as cart,
		Count(Distinct Case When event_type = 'checkout_start' Then user_id End ) as checkout,
		Count(Distinct Case When event_type = 'payment_info' Then user_id End ) as payment,
		Count(Distinct Case When event_type = 'purchase' Then user_id End ) as purchase
    
	From user_events
    Where event_date >= (Select Date_sub(max(event_date), interval 30 day) from user_events)
    Group By traffic_source
)
Select traffic_source,
views,
cart,
purchase,
Round(cart * 100 / views) as views_to_cart_conversion,
Round(purchase * 100 / cart) as cart_to_purchase_conversion,
Round(purchase * 100 / views) as views_to_purchase_conversion

From source_funnel
Order by purchase Desc;


-- Now lets find out the total revenue, and average revenue from a customer
-- How much revenue are we generating from this funnel, and roughly how much each view is making us, and the average order price by the buyers?

With funnel_revenue AS(
	Select 
    COUNT(Case When event_type = 'page_view' Then user_id End ) as total_visitors,
    COUNT(Case When event_type = 'purchase' Then user_id End ) as total_buyers,
    ROUND(SUM(Case When event_type = 'purchase' Then amount End )) as total_revenue,
    COUNT(Case When event_type = 'purchase' Then 1 End ) as total_orders

    From user_events
    Where event_date >= (Select Date_sub(max(event_date), interval 30 day) from user_events)
)

Select
	total_visitors,
	total_buyers,
	total_revenue,
	total_orders,
	ROUND(total_revenue / total_orders) as avg_order_value,
	ROUND(total_revenue / total_buyers) as revenue_per_buyer,
	ROUND(total_revenue / total_visitors) as revenue_per_visitors
 


From funnel_revenue;
    
    


describe user_events;







    
    
