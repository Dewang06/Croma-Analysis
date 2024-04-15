-- alter table customer_transaction_data add column `id` int unsigned primary KEY AUTO_INCREMENT;
-- ALTER TABLE customer_transaction_data
--     MODIFY id int FIRST;

-- alter table festive_data add column `id` int unsigned primary KEY AUTO_INCREMENT;
-- ALTER TABLE festive_data
--     MODIFY id int FIRST;
  
-- alter table campaign_data add column `id` int unsigned primary KEY AUTO_INCREMENT;
-- ALTER TABLE campaign_data
--      MODIFY id int FIRST;
     
-- Seasonality of Demand: 
/*
Identify the seasonality of demand for different Merchant Classes (Air Conditioners, TVs, Washing Machines, etc.).
Analyse the effect of festive seasons on sales volumes. List of Festive seasons and their corresponding durations
every year are provided in the Appendix. Thus, help answer the following:

Q1 Which Merchant Class is most susceptible to seasonal variations and how much is the variation.
Which Merchant Class(es) is/are hardly affected by seasonal variations.
*/
-- SELECT * FROM croma.customer_transaction_data;

-- Following query shows max units sold from a Merchant Class on a particular festival
create or replace view MaxUnits_PerClass_OnFestival as
(
	with Merch_UnitSold_PerSeason as (
	SELECT c.MerchClassDescription, sum(c.OrderedQuantity) as Units_Sold, f.Festive_Occasion
	FROM customer_transaction_data c 
	JOIN festive_data f ON c.OrderDate BETWEEN f.From_2019 AND f.To_2019 
						  OR c.OrderDate BETWEEN f.From_2020 AND f.To_2020 
						  OR c.OrderDate BETWEEN f.From_2021 AND f.To_2021
	where not c.MerchClassDescription = 'Unknown'
	group by c.MerchClassDescription, f.Festive_Occasion
	)
	select t.MerchClassDescription, t.Max_Sold,  m.Festive_Occasion from
	(
		Select max(Units_Sold) as Max_Sold,  MerchClassDescription
		from Merch_UnitSold_PerSeason
		group by MerchClassDescription) as t
	join
	(
		SELECT c.MerchClassDescription, sum(c.OrderedQuantity) as Units_Sold, f.Festive_Occasion
		FROM customer_transaction_data c 
		JOIN festive_data f ON c.OrderDate BETWEEN f.From_2019 AND f.To_2019 
							  OR c.OrderDate BETWEEN f.From_2020 AND f.To_2020 
							  OR c.OrderDate BETWEEN f.From_2021 AND f.To_2021
		where not c.MerchClassDescription = 'Unknown'
		group by c.MerchClassDescription, f.Festive_Occasion
	) as m
	on t.Max_Sold = m.Units_Sold and
	t.MerchClassDescription = m.MerchClassDescription
);



-- Following query shows min units sold from a Merchant Class on a particular festival
create or replace view MinUnits_PerClass_OnFestival as
(
	with Merch_UnitSold_PerSeason as (
	SELECT c.MerchClassDescription, sum(c.OrderedQuantity) as Units_Sold, f.Festive_Occasion
	FROM customer_transaction_data c 
	JOIN festive_data f ON c.OrderDate BETWEEN f.From_2019 AND f.To_2019 
						  OR c.OrderDate BETWEEN f.From_2020 AND f.To_2020 
						  OR c.OrderDate BETWEEN f.From_2021 AND f.To_2021
	where not c.MerchClassDescription = 'Unknown'
	group by c.MerchClassDescription, f.Festive_Occasion
	)
	select t.MerchClassDescription, t.Min_Sold,  m.Festive_Occasion from
	(
		Select min(Units_Sold) as Min_Sold,  MerchClassDescription
		from Merch_UnitSold_PerSeason
		group by MerchClassDescription) as t
	join
	(
		SELECT c.MerchClassDescription, sum(c.OrderedQuantity) as Units_Sold, f.Festive_Occasion
		FROM customer_transaction_data c 
		JOIN festive_data f ON c.OrderDate BETWEEN f.From_2019 AND f.To_2019 
							  OR c.OrderDate BETWEEN f.From_2020 AND f.To_2020 
							  OR c.OrderDate BETWEEN f.From_2021 AND f.To_2021
		where not c.MerchClassDescription = 'Unknown'
		group by c.MerchClassDescription, f.Festive_Occasion
	) as m
	on t.Min_Sold = m.Units_Sold and
	t.MerchClassDescription = m.MerchClassDescription
);



-- Max and min units sold per Merchant Class
create or replace view Max_Min_Units_PerClass as
(
	with Merch_UnitSold_PerSeason as (
	SELECT c.MerchClassDescription, sum(c.OrderedQuantity) as Units_Sold, f.Festive_Occasion
	FROM customer_transaction_data c 
	JOIN festive_data f ON c.OrderDate BETWEEN f.From_2019 AND f.To_2019 
						  OR c.OrderDate BETWEEN f.From_2020 AND f.To_2020 
						  OR c.OrderDate BETWEEN f.From_2021 AND f.To_2021
	where not c.MerchClassDescription = 'Unknown'
	group by c.MerchClassDescription, f.Festive_Occasion
	)
	select MerchClassDescription, 
	max(Units_Sold) as Max_Units_Sold, 
	min(Units_Sold) as Min_Units_Sold, 
	(max(Units_Sold) - min(Units_Sold)) as Difference
	from Merch_UnitSold_PerSeason
	group by MerchClassDescription
);


-- Final Answer 

create table `Seasonal_Variation_By_Merchant_Class` as 
(
	select mn.MerchClassDescription, mn.Max_Units_Sold, m.Festive_Occasion as `Festive_Occasion (Max)`, 
		   mn.Min_Units_Sold, n.Festive_Occasion as `Festive_Occasion (Min)`,
		   round((mn.Difference / mn.Max_Units_Sold) * 100, 2) as `Seasonal_Variation (in %)`
	from max_min_units_perclass mn
	join 
		maxunits_perclass_onfestival m
		on mn.MerchClassDescription = m.MerchClassDescription
		and mn.Max_Units_Sold = m.Max_Sold
	join
		minunits_perclass_onfestival n
		on mn.MerchClassDescription = n.MerchClassDescription
		and mn.Min_Units_Sold = n.Min_Sold
	order by `Seasonal_Variation (in %)` desc
);

-- **INSIGHTS**
/*
	As we can see from the above result, "Cooling & Heating Appliances" Merch Class is most susceptible to seasonal variations
    & the variation is 97.8%. It sold maximum units during Gudi Padwa & minimum units during Gandhi Jayanti.
    
    Calculators, Toys, E-Readers, Dummies are the Merch Classes that are hardly affected by seasonal variations
	& the variations are 0% for all.
*/



/*
Q2 Sales of which Merchant Class(es) is/are highly affected by Diwali. Quantify sales revenue during Diwali
as a percentage of total annual sales revenue for each Merchant Class for each year.
*/

-- Diwali Sales for 2019
create or replace view diwali_sales_2019 as
(
	Select 2019_d.MerchClassDescription,
	(2019_Diwali_Revenue / (2019_Diwali_Revenue + 2019_Non_Diwali_Revenue)) * 100 as `diwali_sales_2019 (in %)` from
	(
		SELECT c.MerchClassDescription, 
		(sum(SaleValue) * sum(c.OrderedQuantity)) as 2019_Diwali_Revenue
			FROM customer_transaction_data c 
			JOIN festive_data f ON c.OrderDate BETWEEN f.From_2019 AND f.To_2019
			where not c.MerchClassDescription = 'Unknown' and
					  Festive_Occasion like '%Deepawali%'
			group by c.MerchClassDescription
	) as 2019_d
	join
	(
		select c.MerchClassDescription, 
		(sum(SaleValue) * sum(c.OrderedQuantity)) as 2019_Non_Diwali_Revenue
			from customer_transaction_data c
			where not c.MerchClassDescription = 'Unknown' and
					  year(c.OrderDate) = '2019' and
					  OrderDate not between (select From_2019 from festive_data where Festive_Occasion like '%Deepawali%') and
											(select To_2019 from festive_data where Festive_Occasion like '%Deepawali%')
			group by c.MerchClassDescription
	) as 2019_nd
	on 2019_d.MerchClassDescription = 2019_nd.MerchClassDescription
	order by `diwali_sales_2019 (in %)` desc
);

-- Diwali Sales for 2020 
create or replace view diwali_sales_2020 as
(
	Select 2020_d.MerchClassDescription,
	(2020_Diwali_Revenue / (2020_Diwali_Revenue + 2020_Non_Diwali_Revenue)) * 100 as `diwali_sales_2020 (in %)` from
	(
		SELECT c.MerchClassDescription, 
		(sum(SaleValue) * sum(c.OrderedQuantity)) as 2020_Diwali_Revenue
			FROM customer_transaction_data c 
			JOIN festive_data f ON c.OrderDate BETWEEN f.From_2020 AND f.To_2020
			where not c.MerchClassDescription = 'Unknown' and
					  Festive_Occasion like '%Deepawali%'
			group by c.MerchClassDescription
	) as 2020_d
	join
	(
		select c.MerchClassDescription, 
		(sum(SaleValue) * sum(c.OrderedQuantity)) as 2020_Non_Diwali_Revenue
			from customer_transaction_data c
			where not c.MerchClassDescription = 'Unknown' and
					  year(c.OrderDate) = '2020' and
					  OrderDate not between (select From_2020 from festive_data where Festive_Occasion like '%Deepawali%') and
											(select To_2020 from festive_data where Festive_Occasion like '%Deepawali%')
			group by c.MerchClassDescription
	) as 2020_nd
	on 2020_d.MerchClassDescription = 2020_nd.MerchClassDescription
	order by `diwali_sales_2020 (in %)` desc
);

-- Diwali Sales for 2021
create or replace view diwali_sales_2021 as
(
	Select 2021_d.MerchClassDescription,
	(2021_Diwali_Revenue / (2021_Diwali_Revenue + 2021_Non_Diwali_Revenue)) * 100 as `diwali_sales_2021 (in %)` from
	(
		SELECT c.MerchClassDescription, 
		(sum(SaleValue) * sum(c.OrderedQuantity)) as 2021_Diwali_Revenue
			FROM customer_transaction_data c 
			JOIN festive_data f ON c.OrderDate BETWEEN f.From_2021 AND f.To_2021
			where not c.MerchClassDescription = 'Unknown' and
					  Festive_Occasion like '%Deepawali%'
			group by c.MerchClassDescription
	) as 2021_d
	join
	(
		select c.MerchClassDescription, 
		(sum(SaleValue) * sum(c.OrderedQuantity)) as 2021_Non_Diwali_Revenue
			from customer_transaction_data c
			where not c.MerchClassDescription = 'Unknown' and
					  year(c.OrderDate) = '2021' and
					  OrderDate not between (select From_2021 from festive_data where Festive_Occasion like '%Deepawali%') and
											(select To_2021 from festive_data where Festive_Occasion like '%Deepawali%')
			group by c.MerchClassDescription
	) as 2021_nd
	on 2021_d.MerchClassDescription = 2021_nd.MerchClassDescription
	order by `diwali_sales_2021 (in %)` desc
);

-- Final Ans
-- Storing result in table to visualize later.
create table `Diwali_Sales_Percentage_By_Merchant_Class` as
(
	select `19`.MerchClassDescription, 
		   COALESCE(`19`.`diwali_sales_2019 (in %)`, 0) as `2019_diwali_sales`,
		   COALESCE(`20`.`diwali_sales_2020 (in %)`, 0) as `2020_diwali_sales`, 
		   COALESCE(`21`.`diwali_sales_2021 (in %)`, 0) as `2021_diwali_sales`,
		   (COALESCE(`19`.`diwali_sales_2019 (in %)`, 0) + COALESCE(`20`.`diwali_sales_2020 (in %)`, 0) + COALESCE(`21`.`diwali_sales_2021 (in %)`, 0)) / 3 as Avg_Diwali_Sales
	from  diwali_sales_2019 as `19`
	left join 
	diwali_sales_2020 as `20`
	on `19`.MerchClassDescription = `20`.MerchClassDescription
	left join
	diwali_sales_2021 as `21`
	on `19`.MerchClassDescription = `21`.MerchClassDescription
	order by Avg_Diwali_Sales desc
);
/*
As we can see the Sales % for "Brand Free Mobile" Merch Class is the highest for 3 year average
2019 highest - Brand Free Mobile
2020 highest - Air Purifier
2021 highest - Connected Homes & Housewares
*/


/*
Q3 Return the Cust ID that received the 5th highest number of 
campaigns for the entire duration (using only the campaign data)
*/
select CustID from (
	select CustID, count(*) as count from campaign_data
	group by CustID
	order by count desc
	limit 4, 1
) as fifthHighestCampaign;






