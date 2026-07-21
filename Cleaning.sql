-- create an staging1 table to handle the dirty data
drop table if exists staging1;
create table if not exists staging1 like dirty_cafe_sales;
insert into staging1 select * from dirty_cafe_sales;

select count(*) from staging1;
-- 10000 ROWS

/* ---------- TRANSACTION ID ---------- */
select `transaction id`
from staging1
group by `transaction id`
having count(`transaction id`) > 1;
-- 	every row is unique
-- `transaction id` has the role of a unique id


/* ---------- ITEM ---------- */
select count(item) from staging1 where item is null or item = ''; 
-- 333 missing values 

select distinct item from staging1;
-- see all the distinct values of item 

update staging1
set item = 'Unknown'
where item is null or item in ('ERROR', 'UNKNOWN', '');

update staging1
set item = trim(item);

select distinct item from staging1;
-- check to see the result of the update 


/* Convert Non-Numeric Quantity/Price/Total_Spent Into NULL Before Making Changes */
-- Updating Quantity 
update staging1
set quantity = 
	case 
		when quantity regexp '^[0-9]+$' then quantity 
        else NULL
	end;
    
-- Updating `Price Per Unit`    
update staging1
set `Price Per Unit` = 
	case 
		when `Price Per Unit` regexp '^[0-9\\.]+$' then `Price Per Unit` 
        else NULL
	end;    

-- Updating `Total Spent`
update staging1
set `Total Spent` = 
	case 
		when `Total Spent` regexp '^[0-9\\.]+$' then `Total Spent`
        else NULL
	end;

    
select count(*) from staging1 where quantity is NULL;
-- 479 MISSING/FAULT VALUES from Quantity

select count(*) from staging1 where `Price Per Unit` is null;
-- 533 MISSING/FAULT VALUES from `Price Per Unit`

select count(*) from staging1 where `Total Spent` is null;
-- 502 MISSING/FAULT VALUES from `Total Spent`


/* ROWS WITH AT LEAST TWO COLUMNS WITH MISSING VALUES */
select *
from staging1
where 
	(quantity is null and `Price Per Unit` is null)	or
    (quantity is null and `Total Spent` is null) 	or 
    (`Price Per Unit` is null and `Total Spent` is null);
-- 58 MISSING/FAULT VAUES FOR AT LEAST TWO COLUMNS

-- WE WILL DELETE THESE 58 ROWS
delete from staging1 s
where 
	(quantity is null and `Price Per Unit` is null)	or
	(quantity is null and `Total Spent` is null) 	or 
	(`Price Per Unit` is null and `Total Spent` is null);
	
-- FOR HELP .................. 
select *
from staging1
where not 
		((quantity is null and `Price Per Unit` is null) or
		(quantity is null and `Total Spent` is null) 	 or 
		(`Price Per Unit` is null and `Total Spent` is null));


/* FILLING MISSING VALUES IN `QUANTITY` */
update staging1
set quantity = `Total Spent` / `Price Per Unit`
where quantity is NULL;

/* FILLING MISSING VALUES IN `Price Per Unit` */
update staging1
set `Price Per Unit` = `Total Spent` / quantity 
where `Price Per Unit` is NULL;

/* FILLING MISSING VALUES IN `Total Spent` */
update staging1
set `Total Spent`= quantity * `Price per unit`
where `Total Spent` is NULL;

/*    CHECK 	*/    
select count(*) from staging1 where quantity is NULL;
select count(*) from staging1 where `Price Per Unit` is null;
select count(*) from staging1 where `Total Spent` is null;


/* ---------- PAYMENT METHOD ---------- */
select distinct `payment method` from staging1;
-- Credit Card, Cash, UNKNOWN, Digital Wallet, ERROR

update staging1
set `payment method` = 'Unknown'
where `payment method` in ('', 'ERROR', 'UNKNOWN');

update staging1
set `payment method` = trim(`payment method`);

select distinct `payment method` from staging1;
-- check to see the result of the update 

 
/* ---------- LOCATION ---------- */
select distinct location from staging1;
-- Takeaway In-store UNKNOWN '' ERROR

update staging1
set location = 'Unknown'
where location in ('', 'ERROR', 'UNKNOWN');

update staging1
set location = trim(location);

select distinct location from staging1;
-- check to see the result of the update -> Takeaway In-store Unknown


/* ---------- TRANSACTION DATE ---------- */
select distinct `transaction date` 
from staging1 
where `transaction date` not regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
-- check all the values without numbers

update staging1 
set `transaction date` = '1900-01-01'
where `transaction date` not regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

select `transaction date`
from staging1
where `transaction date` not regexp '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
-- check to see the result of the update 


-- TABLE WITH CLEAN DATA
drop table if exists clean_table;

create table if not exists clean_table (
	id 				int primary key auto_increment,
    item 			varchar(50) not null,
    quantity 		int not null, 
    price_per_unit  double not null, 
    total_spent 	double not null,
    payment_method 	enum('Credit Card', 'Cash', 'Unknown', 'Digital Wallet') not null, 
    location 		enum('Takeaway', 'In-store', 'Unknown') not null,
    trans_date 		date not null
);


insert into clean_table(item, quantity, price_per_unit, total_spent, payment_method, location, trans_date) 
	select 
		item, 
        quantity, 
        `Price Per Unit`, 
        `Total Spent`,
        `payment method`,
        location,
        str_to_date(`transaction date`, '%Y-%m-%d')
	from staging1;
    