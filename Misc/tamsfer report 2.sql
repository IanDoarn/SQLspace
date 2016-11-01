with s0 as (
SELECT DISTINCT
	s.product_id,
	pc.component_product_id,
	pc.quantity
FROM
	sms.stock s
		LEFT JOIN sms.product_component pc ON s.product_id = pc.product_id
WHERE
	stock_type in (3, 4)
	AND inventory_type = 3
	AND product_type != 2
),

s1 as (
SELECT
	coalesce (p.edi_number, p.product_number) as Kit_ID,
	p.description as kit_description,
	p2.edi_number as component_prod_id,
	p2.description as component_description,
	s0.quantity as component_quantity_in_kit
FROM
	s0
		LEFT JOIN sms.product p ON s0.product_id = p.id
		LEFT JOIN sms.product p2 ON s0.component_product_id = p2.id
WHERE
	p.product_number not like 'ZPB%'
),
pieces_loose_in_whse as (
SELECT
	p.product_number,
	p.edi_number,
	sum(s.quantity_on_hand) AS qoh
FROM 
	sms.stock s
		LEFT JOIN sms.product p ON p.id = s.product_id
WHERE
	s.inventory_type = 3
	and s.stock_type = 1
	and s.location_type = 1
	and s.location_id = 370
GROUP BY
	p.product_number,
	p.edi_number

),
kit_qoh_whse as (
SELECT 
	coalesce(p.edi_number, p.product_number) as edi_number, 
	p.description,
	sum (s.quantity_on_hand) as kit_qoh
FROM 
	sms.stock s 
		left join sms.product p on s.product_id = p.id
WHERE 
	s.inventory_type = 3 
	and s.location_type = 1 
	and s.stock_type in (3, 4)
GROUP BY 
	coalesce (p.edi_number, p.product_number),
	description

),
r_bin_locations as (
SELECT
	p.product_number,
	p.edi_number,
	b.zone || '-' || b.position || '-' || b.shelf as bin
FROM
	sms.stock s
		LEFT JOIN sms.product p ON s.product_id = p.id
		LEFT JOIN sms.bin b ON b.id = s.container_id AND s.container_type = 1
WHERE
	s.inventory_type = 3
	AND s.location_type = 1
	AND s.container_type = 1

),
g_bin_locations as (
SELECT 
	p.product_number,
	p.description,
	b.zone || '-' || b.position || '-' || b.shelf as bin,
	ps.serial_number
FROM
	sms.stock s
		LEFT JOIN sms.product p ON s.product_id = p.id
		LEFT JOIN sms.bin b ON b.id = s.container_id and s.container_type = 1
		LEFT JOIN sms.product_serial ps ON ps.id = s.serial_id
 WHERE
	s.location_type = 1 
	and s.location_id = 370
	and s.stock_type in (3,4)
	and s.container_type = 1

group by
p.product_number,
p.description,
bin,
ps.serial_number
),
s6 as (
SELECT 
	p.product_number, p.edi_number, p.description,
	case when stock_type = 3 then sum(s.quantity_on_hand) end as Valid,
	case when stock_type = 4 then sum(s.quantity_on_hand) end as Invalid
FROM 
	sms.stock s
		LEFT JOIN sms.product p ON s.product_id = p.id
WHERE
	s.inventory_type = 3
	and stock_type in (3,4)
group by
	p.product_number,p.edi_number, p.description,
	s.stock_type),

valid_invalid as (
Select
	s6.product_number, s6.edi_number, s6.description, 
	coalesce(sum(s6.valid),0) as valid,
	coalesce(sum (s6.invalid),0) as invalid,
		case 
			when sum(s6.valid) is null then 1.0
			when sum(s6.invalid) is null then 0.0
				else sum (s6.invalid)/   (sum(s6.valid)+ sum (s6.invalid)) 
		end as Percent_invalid

from
	s6
Group by 
	product_number, edi_number, description
)
SELECT
	s1.kit_id as kit_number,
	s5.serial_number,
	s1.kit_description,
	s3.kit_qoh as kits_in_ci,
	s7.valid,
	s7.invalid,
	s7.Percent_invalid,
	s5.bin as kit_bin_location,
	s1.component_prod_id,
	s1.component_description,
	s1.component_quantity_in_kit as component_kit_par,
	s4.bin as mapped_bin_location,
	coalesce (sum(s2.qoh),0) as loose_in_warehouse,
	min(coalesce (s2.qoh, 0)) over (partition by kit_id) as min_kits_avail_to_build
FROM
	s1
		LEFT JOIN pieces_loose_in_whse s2 ON s1.component_prod_id = s2.edi_number
		LEFT JOIN kit_qoh_whse s3 ON s1.kit_id = s3.edi_number
		LEFT JOIN r_bin_locations s4 ON s1.component_prod_id = s4.edi_number
		LEFT JOIN g_bin_locations s5 ON s1.kit_description = s5.description
		LEFT JOIN valid_invalid s7 ON s1.kit_description = s7.description
WHERE
	s1.kit_id NOT LIKE 'T%'
	AND s1.kit_id NOT LIKE 'R%'
	AND s1.kit_id NOT LIKE 'S%'
	AND s1.kit_id NOT LIKE 'P%'
	AND s1.kit_id NOT LIKE 'C%'
	AND s1.kit_id NOT LIKE 'N%'
	AND s1.kit_id NOT LIKE 'I%'
	AND s1.kit_id NOT LIKE 'H%'
	AND s1.kit_id NOT LIKE 'F%'
	AND s1.kit_id NOT LIKE 'A%'
	AND s1.kit_id NOT LIKE 'Demo Kit 867-5309'
GROUP BY
	s1.kit_id,
	s5.serial_number,
	s1.kit_description,
	s3.kit_qoh,
	s7.valid,
	s7.invalid,
	s7.Percent_invalid,
	s5.bin,
	s2.qoh,
	s1.component_prod_id,
	s1.component_description,
	s1.component_quantity_in_kit,
	s4.bin
ORDER BY
	s7.Percent_invalid desc,
	s1.kit_id,
	s5.serial_number,
	loose_in_warehouse