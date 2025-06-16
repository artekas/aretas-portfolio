--Average age of customers

select round(avg(extract(year from current_date) - cast(year_birth as integer))) as avg_age
from raw.marketing_data
where year_birth not in ('#N/A')

--What is the average age of the customers belonging to each type of marital status?

select marital_status,
       round(avg(extract(year from current_date) - cast(year_birth as integer)), 0) as avg_age
from raw.marketing_data
where year_birth not in ('#N/A')
group by marital_status;

--What is the average age of customers in different income groups?

select 
  case 
    when income between 0 and 40000 then 'low income'
    when income between 40001 and 80000 then 'middle income'
    when income between 80001 and 120000 then 'upper middle income'
    when income > 120000 then 'high income'
  end as income_group,
  round(avg(extract(year from current_date) - cast(year_birth as integer)), 0) as avg_age
from raw.marketing_data
where year_birth not in ('#N/A')
group by income_group;

--the total spend per country

select country,
       sum(amtliq) as total_amtliq,
       sum(amtvege) as total_amtvege,
       sum(amtnonvege) as total_amtnonvege,
       sum(amtpes) as total_amtpes,
       sum(amtchocolates) as total_amtchocolates,
       sum(amtcomm) as total_amtcomm
from raw.marketing_data
group by country;

--create view of total_spend_per_country in reporting 

create table reporting.total_spend_per_country (
    country character varying(5),
    total_amtliq numeric,
    total_amtvege numeric,
    total_amtnonvege numeric,
    total_amtpes numeric,
    total_amtchocolates numeric,
    total_amtcomm numeric);

insert into reporting.total_spend_per_country (country, total_amtliq, total_amtvege, total_amtnonvege, 
total_amtpes, total_amtchocolates, total_amtcomm)
select country,
       sum(amtliq) as total_amtliq,
       sum(amtvege) as total_amtvege,
       sum(amtnonvege) as total_amtnonvege,
       sum(amtpes) as total_amtpes,
       sum(amtchocolates) as total_amtchocolates,
       sum(amtcomm) as total_amtcomm
from raw.marketing_data
group by country;


--create staging table

create table staging.marketing_data as
select *
from raw.marketing_data;

--create total spend per product per country in staging and rename countries to full name 

create table staging.total_spend_per_product_per_country as
select 
    case 
        when country = 'SP' then 'spain'
        when country = 'CA' then 'canada'
        when country = 'AUS' then 'australia'
        when country = 'IND' then 'india'
        when country = 'US' then 'usa'
        when country = 'ME' then 'montenegro'
        when country = 'SA' then 'south africa'
        when country = 'GER' then 'germany'
    end as country,
    sum(amtliq) as total_alcohol,
    sum(amtvege) as total_vegetables,
    sum(amtnonvege) as total_meat,
    sum(amtpes) as total_fish,
    sum(amtchocolates) as total_chocolates,
    sum(amtcomm) as total_commodities
from 
    staging.marketing_data
group by 
    country;

--add to reporting schema

create table reporting.total_spend_per_product_per_country (
    country text,
    total_alcohol numeric,
    total_vegetables numeric,
    total_meat numeric,
    total_fish numeric,
    total_chocolates numeric,
    total_commodities numeric);


insert into reporting.total_spend_per_product_per_country
select * from staging.total_spend_per_product_per_country

--total spend per country (all products)

create table staging.total_spend_per_country (
    country text,
    total_spend_per_country numeric);

select 
    country,
    sum(total_alcohol + total_vegetables + total_meat + total_fish + total_chocolates
	+ total_commodities) as total_spend_per_country
from staging.total_spend_per_product_per_country
group by country;

-- Insert total spend per country into the new table
insert into staging.total_spend_per_country
select 
    country,
    sum(total_alcohol + total_vegetables + total_meat + total_fish + total_chocolates
	+ total_commodities) as total_spend_per_country
from staging.total_spend_per_product_per_country
group by country;

select *
from staging.total_spend_per_country

--the most popular products in each country 
select 
    country, 
    'alcohol' as product,
    sum(total_alcohol) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'vegetables' as product,
    sum(total_vegetables) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'meat' as product,
    sum(total_meat) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'fish' as product,
    sum(total_fish) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'chocolates' as product,
    sum(total_chocolates) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'commodities' as product,
    sum(total_commodities) as total_spent
from staging.total_spend_per_product_per_country
group by country
order by total_spent desc;


-- Create a new table in reporting schema for the most popular products per country

create table reporting.most_popular_products_per_country as
select 
    country, 
    'alcohol' as product,
    sum(total_alcohol) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'vegetables' as product,
    sum(total_vegetables) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'meat' as product,
    sum(total_meat) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'fish' as product,
    sum(total_fish) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'chocolates' as product,
    sum(total_chocolates) as total_spent
from staging.total_spend_per_product_per_country
group by country
union all
select 
    country,
    'commodities' as product,
    sum(total_commodities) as total_spent
from staging.total_spend_per_product_per_country
group by country
order by total_spent desc;

--the most popular products based on marital status
select 
    case 
        when marital_status in ('Alone') then 'Single'
        else marital_status
    end as marital_status,
    sum(amtliq) as total_alcohol,
    sum(amtvege) as total_vegetables,
    sum(amtnonvege) as total_meat,
    sum(amtpes) as total_fish,
    sum(amtchocolates) as total_chocolates,
    sum(amtcomm) as total_commodities
from 
    staging.marketing_data
group by 
    case 
        when marital_status in ('Alone') then 'Single'
        else marital_status
    end
order by 
    total_alcohol desc,
    total_vegetables desc,
    total_meat desc,
    total_fish desc,
    total_chocolates desc,
    total_commodities desc;

-- The most popular products based on children or teens in the home
select 
    case 
        when kidhome > 0 and teenhome > 0 then 'children and teens'
        when kidhome > 0 and teenhome = 0 then 'children only'
        when kidhome = 0 and teenhome > 0 then 'teens only'
        else 'no children or teens'
    end as family_status,
    sum(amtliq) as total_alcohol,
    sum(amtvege) as total_vegetables,
    sum(amtnonvege) as total_meat,
    sum(amtpes) as total_fish,
    sum(amtchocolates) as total_chocolates,
    sum(amtcomm) as total_commodities
from 
    staging.marketing_data
group by 
    case 
        when kidhome > 0 and teenhome > 0 then 'children and teens'
        when kidhome > 0 and teenhome = 0 then 'children only'
        when kidhome = 0 and teenhome > 0 then 'teens only'
        else 'no children or teens'
    end
order by 
    total_alcohol desc,
    total_vegetables desc,
    total_meat desc,
    total_fish desc,
    total_chocolates desc,
    total_commodities desc;

-- total spend by customers who complained in the last 2 years
select 
    sum(amtliq) as total_alcohol,
    sum(amtvege) as total_vegetables,
    sum(amtnonvege) as total_meat,
    sum(amtpes) as total_fish,
    sum(amtchocolates) as total_chocolates,
    sum(amtcomm) as total_commodities
from 
    staging.marketing_data
where 
    complain = true;


-- average income of customers who accepted the last campaign's offer
select 
    round(avg(income), 0) as avg_income
from 
    staging.marketing_data
where 
    response = true;

-- total spend by education level
select 
    education,
    sum(amtliq) as total_alcohol,
    sum(amtvege) as total_vegetables,
    sum(amtnonvege) as total_meat,
    sum(amtpes) as total_fish,
    sum(amtchocolates) as total_chocolates,
    sum(amtcomm) as total_commodities
from 
    staging.marketing_data
group by 
    education
order by 
    total_alcohol desc;

-- distribution of customers by income range
select 
    case 
        when income < 30000 then 'Low income'
        when income between 30000 and 60000 then 'Middle income'
        when income between 60000 and 90000 then 'Upper middle income'
        else 'High income'
    end as income_range,
    count(*) as customer_count
from 
    staging.marketing_data
group by 
    income_range
order by 
    customer_count desc;

-- average recency by marital status
select 
    case 
        when marital_status in ('Single', 'Alone') then 'Single'
        else marital_status
    end as marital_status_combined,
    round(avg(recency), 0) as avg_recency
from 
    staging.marketing_data
group by 
    marital_status_combined;

-- total number of purchases from in-store and website
select 
    'in-store purchases' as purchase_channel,
    sum(numwalkinpur) as total_in_store,
    0 as total_online
from 
    staging.marketing_data
group by 
    purchase_channel

union all

select 
    'website purchases' as purchase_channel,
    0 as total_in_store,
    sum(numwebbuy) as total_online
from 
    staging.marketing_data
group by 
    purchase_channel;

-- total spend by response to campaign
select 
    response,
    sum(amtliq) as total_alcohol,
    sum(amtvege) as total_vegetables,
    sum(amtnonvege) as total_meat,
    sum(amtpes) as total_fish,
    sum(amtchocolates) as total_chocolates,
    sum(amtcomm) as total_commodities
from 
    staging.marketing_data
group by 
    response;


--create ad_data staging table 
create table staging.ad_data as
select *
from raw.ad_data;

select *
from staging.marketing_data


--create a join between marketing and ad data 
select 
    md.id,
    md.year_birth,
    md.education,
    md.marital_status,
    md.income,
    md.kidhome,
    md.teenhome,
    md.dt_customer,
    md.numdeals,
    md.numwebbuy,
    md.numwalkinpur,
    md.numvisits,
    md.response,
    md.complain,
    md.country,
    md.count_success,
    ad.bulkmail_ad,
    ad.twitter_ad,
    ad.instagram_ad,
    ad.facebook_ad,
    ad.brochure_ad
from 
    staging.marketing_data md
inner join 
    staging.ad_data ad
    on md.id = ad.id;

-- most effective ad campaign platform by country
select 
    md.country,
    sum(case when ad.bulkmail_ad then 1 else 0 end * md.count_success) as bulkmail_effectiveness,
    sum(case when ad.twitter_ad then 1 else 0 end * md.count_success) as twitter_effectiveness,
    sum(case when ad.instagram_ad then 1 else 0 end * md.count_success) as instagram_effectiveness,
    sum(case when ad.facebook_ad then 1 else 0 end * md.count_success) as facebook_effectiveness,
    sum(case when ad.brochure_ad then 1 else 0 end * md.count_success) as brochure_effectiveness
from 
    staging.marketing_data md
inner join 
    staging.ad_data ad
    on md.id = ad.id
group by 
    md.country
order by 
    bulkmail_effectiveness desc,
    twitter_effectiveness desc,
    instagram_effectiveness desc,
    facebook_effectiveness desc,
    brochure_effectiveness desc;

-- most effective ad platform by marital status
select 
    case 
        when md.marital_status in ('Single', 'Alone') then 'Single' 
        else md.marital_status 
    end as marital_status,
    sum(case when ad.twitter_ad then 1 else 0 end * md.count_success) as twitter_effectiveness,
    sum(case when ad.instagram_ad then 1 else 0 end * md.count_success) as instagram_effectiveness,
    sum(case when ad.facebook_ad then 1 else 0 end * md.count_success) as facebook_effectiveness,
    sum(case when ad.bulkmail_ad then 1 else 0 end * md.count_success) as bulkmail_effectiveness,
    sum(case when ad.brochure_ad then 1 else 0 end * md.count_success) as brochure_effectiveness
from 
    staging.marketing_data md
inner join 
    staging.ad_data ad
    on md.id = ad.id
group by 
    marital_status
order by 
    twitter_effectiveness desc, 
    instagram_effectiveness desc, 
    facebook_effectiveness desc,
    bulkmail_effectiveness desc,
    brochure_effectiveness desc;


-- most effective social media platforms per country and product
select 
    md.country,
    case 
        when ad.twitter_ad then 'twitter'
        when ad.instagram_ad then 'instagram'
        when ad.facebook_ad then 'facebook'
        when ad.bulkmail_ad then 'bulkmail'
        when ad.brochure_ad then 'brochure'
        else 'no ad'
    end as advertising_platform,
    sum(case when ad.twitter_ad then 1 else 0 end * md.count_success) as twitter_effectiveness,
    sum(case when ad.instagram_ad then 1 else 0 end * md.count_success) as instagram_effectiveness,
    sum(case when ad.facebook_ad then 1 else 0 end * md.count_success) as facebook_effectiveness,
    sum(case when ad.bulkmail_ad then 1 else 0 end * md.count_success) as bulkmail_effectiveness,
    sum(case when ad.brochure_ad then 1 else 0 end * md.count_success) as brochure_effectiveness,
    sum(md.amtliq) as total_alcohol,
    sum(md.amtvege) as total_vegetables,
    sum(md.amtnonvege) as total_meat,
    sum(md.amtpes) as total_fish,
    sum(md.amtchocolates) as total_chocolates,
    sum(md.amtcomm) as total_commodities
from 
    staging.marketing_data md
inner join 
    staging.ad_data ad
    on md.id = ad.id
group by 
    md.country, advertising_platform
order by 
    md.country, 
    twitter_effectiveness desc, 
    instagram_effectiveness desc, 
    facebook_effectiveness desc,
    bulkmail_effectiveness desc, 
    brochure_effectiveness desc;

-- average recency of customers based on receiving Twitter, Instagram or Facebook ads
select 
    case 
        when ad.twitter_ad then 'received twitter ad'
        when ad.instagram_ad then 'received instagram ad'
        when ad.facebook_ad then 'received facebook ad'
        else 'did not receive any social media ad'
    end as ad_campaign,
    round(avg(md.recency), 0) as avg_recency
from 
    staging.marketing_data md
inner join 
    staging.ad_data ad
    on md.id = ad.id
group by 
    ad_campaign
order by 
    avg_recency desc;


-- total spend per advertising platform per country (all product categories)
select 
    md.country,
    sum(case when ad.twitter_ad then md.amtliq else 0 end) as total_twitter_alcohol,
    sum(case when ad.instagram_ad then md.amtliq else 0 end) as total_instagram_alcohol,
    sum(case when ad.facebook_ad then md.amtliq else 0 end) as total_facebook_alcohol,
    sum(case when ad.bulkmail_ad then md.amtliq else 0 end) as total_bulkmail_alcohol,
    sum(case when ad.brochure_ad then md.amtliq else 0 end) as total_brochure_alcohol,

    sum(case when ad.twitter_ad then md.amtvege else 0 end) as total_twitter_vegetables,
    sum(case when ad.instagram_ad then md.amtvege else 0 end) as total_instagram_vegetables,
    sum(case when ad.facebook_ad then md.amtvege else 0 end) as total_facebook_vegetables,
    sum(case when ad.bulkmail_ad then md.amtvege else 0 end) as total_bulkmail_vegetables,
    sum(case when ad.brochure_ad then md.amtvege else 0 end) as total_brochure_vegetables,

    sum(case when ad.twitter_ad then md.amtnonvege else 0 end) as total_twitter_meat,
    sum(case when ad.instagram_ad then md.amtnonvege else 0 end) as total_instagram_meat,
    sum(case when ad.facebook_ad then md.amtnonvege else 0 end) as total_facebook_meat,
    sum(case when ad.bulkmail_ad then md.amtnonvege else 0 end) as total_bulkmail_meat,
    sum(case when ad.brochure_ad then md.amtnonvege else 0 end) as total_brochure_meat,

    sum(case when ad.twitter_ad then md.amtpes else 0 end) as total_twitter_fish,
    sum(case when ad.instagram_ad then md.amtpes else 0 end) as total_instagram_fish,
    sum(case when ad.facebook_ad then md.amtpes else 0 end) as total_facebook_fish,
    sum(case when ad.bulkmail_ad then md.amtpes else 0 end) as total_bulkmail_fish,
    sum(case when ad.brochure_ad then md.amtpes else 0 end) as total_brochure_fish,

    sum(case when ad.twitter_ad then md.amtchocolates else 0 end) as total_twitter_chocolates,
    sum(case when ad.instagram_ad then md.amtchocolates else 0 end) as total_instagram_chocolates,
    sum(case when ad.facebook_ad then md.amtchocolates else 0 end) as total_facebook_chocolates,
    sum(case when ad.bulkmail_ad then md.amtchocolates else 0 end) as total_bulkmail_chocolates,
    sum(case when ad.brochure_ad then md.amtchocolates else 0 end) as total_brochure_chocolates,

    sum(case when ad.twitter_ad then md.amtcomm else 0 end) as total_twitter_commodities,
    sum(case when ad.instagram_ad then md.amtcomm else 0 end) as total_instagram_commodities,
    sum(case when ad.facebook_ad then md.amtcomm else 0 end) as total_facebook_commodities,
    sum(case when ad.bulkmail_ad then md.amtcomm else 0 end) as total_bulkmail_commodities,
    sum(case when ad.brochure_ad then md.amtcomm else 0 end) as total_brochure_commodities

from 
    staging.marketing_data md
inner join 
    staging.ad_data ad
    on md.id = ad.id
group by 
    md.country
order by 
	total_instagram_alcohol desc,
    total_twitter_alcohol desc,
    total_facebook_alcohol desc,
    total_bulkmail_alcohol desc,
    total_brochure_alcohol desc,
    total_twitter_vegetables desc,
    total_instagram_vegetables desc,
    total_facebook_vegetables desc,
    total_bulkmail_vegetables desc,
    total_brochure_vegetables desc,
    total_twitter_meat desc,
    total_instagram_meat desc,
    total_facebook_meat desc,
    total_bulkmail_meat desc,
    total_brochure_meat desc,
    total_twitter_fish desc,
    total_instagram_fish desc,
    total_facebook_fish desc,
    total_bulkmail_fish desc,
    total_brochure_fish desc,
    total_twitter_chocolates desc,
    total_instagram_chocolates desc,
    total_facebook_chocolates desc,
    total_bulkmail_chocolates desc,
    total_brochure_chocolates desc,
    total_twitter_commodities desc,
    total_instagram_commodities desc,
    total_facebook_commodities desc,
    total_bulkmail_commodities desc,
    total_brochure_commodities desc;

-- total spend for each product by marital status
select 
    case 
    when md.marital_status in ('Single', 'Alone') then 'Single'
    else md.marital_status 
    end as marital_status_grouped,
    sum(md.amtliq) as total_alcohol,
    sum(md.amtvege) as total_vegetables,
    sum(md.amtnonvege) as total_meat,
    sum(md.amtpes) as total_fish,
    sum(md.amtchocolates) as total_chocolates,
    sum(md.amtcomm) as total_commodities
from 
    staging.marketing_data md
group by 
    marital_status_grouped
order by 
    total_alcohol desc,
    total_vegetables desc,
    total_meat desc,
    total_fish desc,
    total_chocolates desc,
    total_commodities desc;

-- correlation between marital status and number of deals purchased
select 
    case 
    when md.marital_status in ('Single', 'Alone') then 'Single'
    else md.marital_status 
    end as marital_status_grouped,   
    sum(md.numdeals) as total_deals_purchased
from 
    staging.marketing_data md
group by 
    marital_status_grouped
order by 
    total_deals_purchased desc;

-- Revenue generated by marital status for Twitter ads, combining 'Single' and 'Alone'
select 
    case 
        when md.marital_status in ('Single', 'Alone') then 'Single'
        else md.marital_status
    end as marital_status_combined,
    sum(case when ad.twitter_ad then md.numdeals else 0 end) as total_deals_from_twitter
from 
    staging.marketing_data md
inner join 
    staging.ad_data ad
on 
    md.id = ad.id
group by 
    marital_status_combined
order by 
    total_deals_from_twitter desc;

-- Campaign conversion rate for alcohol per social media platform vs Bullmail & Brochure
select 
    case 
        when ad.twitter_ad then 'Twitter'
        when ad.instagram_ad then 'Instagram'
        when ad.facebook_ad then 'Facebook'
        else 'Other'
    end as ad_platform,
    sum(md.amtliq) as total_amtliq,
    count(distinct md.id) as total_leads, 
    sum(md.numdeals) as total_purchases,
    (sum(md.numdeals)::float / count(distinct md.id)) * 100 as conversion_rate
from 
    staging.marketing_data md
inner join 
    staging.ad_data ad
on 
    md.id = ad.id
group by 
    ad_platform
order by 
    conversion_rate desc;

select *
from staging.ad_data 


