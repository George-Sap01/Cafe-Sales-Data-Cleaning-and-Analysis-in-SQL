
select (select count(payment_method) from clean_table where payment_method = 'Unknown') / count(*) from clean_table;
-- 31.76 %
select count(payment_method) from clean_table where payment_method = 'Unknown'; 
-- 3158 values

select (select count(location) from clean_table where location = 'Unknown') / count(*) from clean_table;
-- 39.63 %
select count(location) from clean_table where location = 'Unknown';
-- 3940 values


/*
    Replace missing values in 'location' and 'payment_method' 
    with the most frequent category (mode) for each column.
*/

-- creating the clean_table2
drop table if exists clean_table2;

create table if not exists clean_table2(
	id 				int primary key auto_increment,
    item 			varchar(50) not null,
    quantity 		int not null, 
    price_per_unit  double not null, 
    total_spent 	double not null,
    payment_method 	enum('Credit Card', 'Cash', 'Unknown', 'Digital Wallet') not null, 
    location 		enum('Takeaway', 'In-store', 'Unknown') not null,
    trans_date 		date not null -- 1900-01-01 as filler date
);

insert into clean_table2(item, quantity, price_per_unit, total_spent, payment_method, location, trans_date) 
	select 
		item, 
        quantity, 
        `Price Per Unit`, 
        `Total Spent`,
        `payment method`,
        location,
        str_to_date(`transaction date`, '%Y-%m-%d')
	from staging1;

-- location column 
with cte_a as(
	select location, count(location)
    from clean_table2
    where location != 'Unknown'
    group by location
    order by 2 desc
    limit 1
    
)
update clean_table2
set location = (select location from cte_a)
where location = 'Unknown';

select distinct location 
from clean_table2;
-- check the results 

-- payment method
with cte_a as(
	select payment_method, count(payment_method)
    from clean_table2
    where payment_method != 'Unknown'
    group by payment_method
    order by 2 desc
    limit 1
    
)
update clean_table2
set payment_method = (select payment_method from cte_a)
where payment_method = 'Unknown';

select distinct payment_method
from clean_table2;
-- check the results 
