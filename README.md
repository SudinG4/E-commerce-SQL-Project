# E-Commerce SQL Analysis
## Project Overview
A SQL project analyzing user behavior through an e-commerce purchase funnel, from product page views through checkout to final purchase using MySQL. The dataset was fetched from online. I approached it as a hypothetical Data Analyst investigating funnel performance, crafting the business questions below based on what a real stakeholder would want to know.

Core question: Where in the customer journey are we losing the most potential revenue, and which traffic sources are worth investing more in?

The analysis covers four stages: funnel volume, conversion rates, traffic source segmentation, and revenue metrics.

## Project Objectives
- Create and manage the data in MySQL
- Using SQL find patterns/relationships in the dataset
- Explore the purchase journey of the viewers on the website
- Answer the business-questions crafted on real world scenario

## Key Questions Answered

1. How many unique customers reached each stage of the purchase journey from viewing a product to completing a purchase in the last 30 days?
2. At which stage in the funnel are we losing the most customers, and what's our overall view_to_purchase conversion rate?
3. Which traffic source from organic, paid, or social brings the most customers, and which one converts them most effectively once they arrive?
4. How much revenue are we generating from this funnel, and roughly how much each view is making us, and the average order price by the buyers?


## Data Dictionary
| Column Name    | Description                                          | Data Type      |
|----------------|-------------------------------------------------------|----------------|
| event_id       | Unique event ID                                       | Integer        |
| user_id        | Unique identifier for the user                        | Integer        |
| event_type     | Type of action (page_view, add_to_cart, checkout_start, payment_info, purchase) | Text |
| event_date     | Date the event occurred                                | Date           |
| product_id     | Identifier for the product involved                    | Integer        |
| amount         | Transaction value (populated for purchase events)       | Decimal(10,2)  |
| traffic_source | Channel the user arrived from (organic, paid, social)  | Text           |


## Tools Use
  SQL - MySQL Workbench


## SQL Analysis and Queries
### Loading the dataset, checking the proper data types, modifying the type of columns, and re checking for final use
```sql
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
```

### Q1.How many unique customers reached each stage of the purchase journey from viewing a product to completing a purchase in the last 30 days?
```sql
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
-- ANS:
/*
Stage1_View = 4,291
Stage2_Cart = 1,338
Stage3_Checkout = 954
Stage4_Payment = 770
Stage5_Purchase = 709
/
```
<img width="1470" height="956" alt="q1" src="https://github.com/user-attachments/assets/75bc0857-057b-47af-8131-0dcdc2348edc" />


### Q2.At which stage in the funnel are we losing the most customers, and what's our overall view-to-purchase conversion rate?
```sql
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
-- We are loosing the most customers from view to cart, 69% drop, and only 31% move forward with their orders added to cart.
-- View to cart = 31 %
-- Cart to Checkout = 71%
-- Checkout to Payment = 81%
-- Payment to Purchase = 92%
-- Overall Viewer to Buyer Conversion rate is only 17%
```
<img width="1470" height="956" alt="q2" src="https://github.com/user-attachments/assets/6627ecd1-f69f-4b95-8367-6816e3cef22b" />

### Q3.Which traffic source from organic, paid, social brings in the most customers, and which one converts them most effectively once they arrive?
```sql
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

-- Organic promotion brings in the most views i.e 1,757
-- Whereas, the viewer to buyer conversion is the highest in email with 34% conversion rate.
```
<img width="1470" height="956" alt="q3" src="https://github.com/user-attachments/assets/e310bbe9-74b6-4599-8012-2ec96e818ed8" />

### Q4.How much revenue are we generating from this funnel, and roughly how much each view is making us, and the average order price by the buyers?
```sql
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
-- The total revenue generated is $76,192.
-- Total orders placed are 709, with average order price of $107.
-- For a total of 4,291 viewers, the revenue per viewer is only $18.
-- Revenue per buyer is $107.
```
<img width="1470" height="956" alt="q4" src="https://github.com/user-attachments/assets/a14cacc5-bef0-4bd1-b137-9c3e4aa8d1cc" />


## Key Findings
- Biggest drop is in view to cart, almost 70% drop. Only 30-31% viewers moved to second stage, and rest left the site possibly.
- Email, bringing in the least views, actually converted 34% of its viewer to buyer.
- Only 17% of the total viewers actually ordered an item, with an average order of $107.



## Recommendation
- For UI/UX design recommendation, Do not touch the checkout to purchase flow design. As it is roughly converting 80% audience to buy an item. Instead, a rigorous A/B testing with different designs for Product page --> Add To Cart --> Checkout should be done, as most of our customers are lost there.
- Marketing Strategy, Social media having the highest traffic had the least buyers. Reduction on Social Media Ads, and Increment budget on email marketing can roughly 2X the revenue through email.
- Financial Strategy, Since our Average Per Customer Spending is only $107, if we are spending $20-30, then it might be best to set a strict Customer Acquisition Cost (CAC) limit. No profit would be enjoyed if the Average order is low and spending for acquiring customer is almost 30% of the average order.






