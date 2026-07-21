/* all the queries are on the clean_table2 */

-- money spent on each item
select item, sum(total_spent) 'money spent on each item'
from clean_table2
where item != 'Unknown'
group by item
order by 2 desc;

select min(trans_date), max(trans_date)
from clean_table2
where trans_date != '1900-01-01';
-- 2023-01-01 - 2023-12-31


-- total_spentings for each item per category 
select 
	coalesce(item, 'All items') item, 
    coalesce(location, 'All locations') location,
    sum(total_spent) "Spentings"
from clean_table2
where item != 'Unknown'
group by item, location with rollup;



-- Monthly Units Sold by Item (Including Totals)
with cte_a as (
	select 
		*,
        date_format(trans_date, '%M') 'Month'
    from clean_table2
    where trans_date != '1900-01-01'
)

select 
	coalesce(month, 'All Months') month, 
	coalesce(item, 'All Items') item,
    sum(quantity) '# of units sold'
from cte_a
where item <> 'Unknown'
group by month, item with rollup;


-- Three Most Sold Items Per Month 
with cte_a as (
	select 
		*, 
        date_format(trans_date, '%m') num_month,
        monthname(trans_date) month_name
    from clean_table2
    where trans_date != '1900-01-01'
),
cte_b as (
	select num_month, month_name, item, sum(quantity) num
	from cte_a
	where item <> 'Unknown'
	group by num_month, month_name, item
),
cte_c as(
	select *, rank() over(partition by num_month order by num desc) r
    from cte_b
)

select month_name, item, num
from cte_c
where r < 4
order by num_month, num desc;


set @item = 'Cake';

-- Monthly @item's sales summary (units sold and revenue)
with cte_a as (
	select 
		*,
        extract(month from trans_date) num_month
    from clean_table2
    where trans_date != '1900-01-01' and item = @item
)
select 
	item,
    case num_month
		when 1 then 'January'
        when 2 then 'February'
        when 3 then 'March'
        when 4 then 'April'
        when 5 then 'May'
        when 6 then 'June'
        when 7 then 'July'
        when 8 then 'August'
        when 9 then 'September'
        when 10 then 'October'
        when 11 then 'November'
        when 12 then 'December'
	end as Month,
    sum(quantity) as '# of units sold',
    sum(total_spent) as 'total money per month' 
from cte_a
group by num_month
order by num_month asc;


-- Top 3 Best-Selling Items by Day of the Week (Units Sold & Revenue)
with cte_a as (
	select 
		*,
		date_format(trans_date, '%w') dow
    from clean_table2
    where trans_date != '1900-01-01' and item <> 'Unknown'
),
cte_b as(
	select 
		dow,
		item,
		sum(quantity) as num_of_units_sold,
		sum(total_spent) as total_money_per_month 
	from cte_a
	group by dow, item 
),
cte_c as (
	select *, rank() over(partition by dow order by num_of_units_sold desc) r
    from cte_b
)

select 
	case dow
		when 0 then 'Sunday'
        when 1 then 'Monday'
        when 2 then 'Tuesday'
        when 3 then 'Wednesday'
        when 4 then 'Thursday'
        when 5 then 'Friday'
        when 6 then 'Saturday'
	end as 'Day of the week',
	item,
    num_of_units_sold,
    total_money_per_month
from cte_c
where r < 4
order by dow asc;


-- Sales Distribution by Monthly Period (Units Sold & Revenue)
with cte_a as (
	select 
		*,
		extract(day from trans_date) dom 
    from clean_table2
    where trans_date != '1900-01-01' and item <> 'Unknown'
),
cte_b as(
	select 
		*, 
        case
			when dom between 1 and 10 then '1-10'
            when dom between 11 and 20 then '11-20'
            else '21-31'
		end as monthly_period
	from cte_a
)

select 
	monthly_period, 
    sum(quantity) num_of_units_sold,
	sum(total_spent) as total_money_per_month 
from cte_b
group by monthly_period;


-- Top 3 Best-Selling Items by Monthly Period (Units Sold & Revenue)
with cte_a as (
	select 
		*,
		extract(day from trans_date) dom 
    from clean_table2
    where trans_date != '1900-01-01' and item <> 'Unknown'
),
cte_b as(
	select 
		*, 
        case
			when dom between 1 and 10 then '1-10'
            when dom between 11 and 20 then '11-20'
            else '21-31'
		end as monthly_period
	from cte_a
),
cte_c as(
	select 
		monthly_period,
        item,
		sum(quantity) num_of_units_sold,
		sum(total_spent) as total_money_per_month 
	from cte_b
	group by monthly_period, item
),
cte_d as(
	select *, rank() over(partition by monthly_period order by num_of_units_sold desc) r
    from cte_c
)

select 
	monthly_period,
    item,
    num_of_units_sold,
    total_money_per_month
from cte_d
where r < 4;


-- Payment Method Preferences by Location, pivot-style table
select 
    location,
    sum(case when payment_method = 'Credit Card' then 1 else 0 end) as credit_card_count,
    sum(case when payment_method = 'Digital Wallet' then 1 else 0 end) as digital_wallet_count,
    sum(case when payment_method = 'Cash' then 1 else 0 end) as cash_count
from clean_table2
group by location;

-- specific dates that generated revenue HIGHER than the daily average for the entire year
with daily_revenue as (
    select trans_date, sum(total_spent) as daily_total
    from clean_table2
    where trans_date != '1900-01-01'
    group by trans_date
)
select trans_date, daily_total
from daily_revenue
where daily_total > (select avg(daily_total) from daily_revenue)
order by daily_total desc;



-- Revenue Momentum (Month-over-Month Growth)
with cte_a as(
	select 
		*,
        extract(month from trans_date) num_month
    from clean_table2
    where trans_date != '1900-01-01'
),
cte_b as(
	select num_month, sum(total_spent) as total
    from cte_a
    group by num_month
),
cte_c as(
	select *, lag(total, 1) over(order by num_month asc) previous
    from cte_b
)

select 
	case num_month
		when 1 then 'January'
        when 2 then 'February'
        when 3 then 'March'
        when 4 then 'April'
        when 5 then 'May'
        when 6 then 'June'
        when 7 then 'July'
        when 8 then 'August'
        when 9 then 'September'
        when 10 then 'October'
        when 11 then 'November'
        when 12 then 'December'
	end as Month,
    total,
    case 
		when previous is null then 'No previous record'
        else concat(round((total - previous) / previous * 100, 2), ' %')
		end as 'Month-over-Month Growth' 
from cte_c
order by num_month;