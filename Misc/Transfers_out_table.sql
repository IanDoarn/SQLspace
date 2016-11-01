with packages as (
select
	'PKG' || '-' || pk.id as package_number,
	movement_id,
	case
		when pk.status = 4 then 'SHIPPED' 
		when pk.status = 3 then 'SHIPPING'
	end as status,
	case
		when pk.distributor_id = 168 then 'FROM SOUTHAVEN' 
	end as from_location,
	
	to_char(pk.shipped_date, 'YYYY-MM-DD') as shipped_date,
	case
		when	pk.to_distributor_id = d.id then 'SHIPPED TO' || '-->' || d.city || ',' || d.state || ',' || d.country
	end as shipped_to
from
	sms.package pk
		LEFT JOIN sms.distributor d ON pk.to_distributor_id = d.id
where
	pk.status in (3,4)
	AND pk.inventory_type = 3
	and pk.distributor_id = 168
	and pk.shipped_date = '2016-06-23'
Order by
	shipped_date desc
),
transfers as (
SELECT
	t.id	as transfer,
	t.movement_id,
	p.product_number,
	p.edi_number,
	p.description,
	t.assigned_user_id,
	u.username,
	t.to_kit_serial_id,
	t.to_kit_product_id
FROM
	sms.transfer t
		LEFT JOIN sms.product p ON p.id = t.product_id 
		LEFT JOIN sms.user_table u ON t.assigned_user_id = u.id
WHERE
	t.location_type = 1
	and t.location_id = 370
	and t.status in (1,2)
),
s4 as (  
SELECT DISTINCT
  s.product_id,
  pc.component_product_id,
  pc.quantity
FROM
  sms.stock s
    LEFT JOIN sms.product_component pc ON s.product_id = pc.product_id
WHERE
  stock_type = 3
  AND inventory_type = 3
),

s5 as (  --7292 lines no issues
SELECT
  p.product_number as kit_product_number, 
  p.edi_number as kit_edi,  
  p.description as kit_description,
  p2.product_number as component_product_number,
  p2.edi_number as component_prod_id,
  p2.description as component_description,
  s4.quantity as component_quantity_in_kit
FROM 
  s4
    LEFT JOIN sms.product p ON s4.product_id = p.id
    LEFT JOIN sms.product p2 ON s4.component_product_id = p2.id
WHERE 
  p.product_number not like 'ZPB%'
),
s6 as (
SELECT
	p.id,
  p.product_number,
  p.edi_number,
  p.description,
  ps.serial_number,
  s.serial_id,
  d.zone || '-' || d.position || '-' || d.shelf as g_bin
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN bins_v2 d on d.bin_id = s.container_id and s.container_type = 1
    LEFT JOIN sms.product_serial ps on ps.id = s.serial_id
WHERE
  s.stock_type in (3,4)
  AND s.distributor_id =168
  and s.inventory_type = 3
  and s.location_type = 1
  and s.container_type = 1
  and d.zone similar to 'G%'

GROUP BY
  g_bin,
  p.product_number,
  p.edi_number,
  p.description,
  ps.serial_number,
  s.serial_id,
  p.id

ORDER BY 
	p.product_number
),
s7 as (
SELECT
  s5.kit_product_number,
  s5.kit_edi,
  s5.kit_description,
  s5.component_product_number,
  s5.component_prod_id,
  s5.component_description,
  s5.component_quantity_in_kit  
FROM
  s5
 )
Select
	s2.transfer as transfer_number,
	s1.movement_id as movement_number,
	s1.package_number,
	s7.kit_product_number,
	s7.kit_edi,
	s7.kit_description,
	s6.serial_number,
	s6.g_bin,
	s7.component_product_number,
	s7.component_prod_id,
	s7.component_description,
	s7.component_quantity_in_kit , 
	s2.assigned_user_id,
	s2.username,
	s1.status,
	s1.from_location,
	s1.shipped_date,
	s1.shipped_to
FROM
	packages s1
		LEFT JOIN transfers s2 ON s1.movement_id = s2.movement_id
		LEFT JOIN s7 on s2.product_number = s7.kit_product_number and s2.edi_number = s7.kit_edi AND s2.description = s7.kit_description
		LEFT JOIN s6 ON s2.to_kit_product_id = s6.id AND s2.to_kit_serial_id = s6.serial_id