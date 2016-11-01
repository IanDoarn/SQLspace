with s1 as (
SELECT
	s.product_id,
	pc.component_product_id,
	pc.quantity
FROM
	sms.stock s
		LEFT JOIN sms.product_component pc ON s.product_id = pc.product_id

where
	stock_type in (3, 4)
	and inventory_type = 3),

s2 as (
SELECT
	coalesce (p.edi_number, p.product_number) as Kit_ID,
	p.description as kit_description,
	p2.edi_number as component_prod_id,
	p2.description as component_description,
	s1.quantity as component_quantity_in_kit
FROM
	s1
		LEFT JOIN sms.product p ON s1.product_id = p.id
		LEFT JOIN sms.product p2 ON s1.component_Product_id = p2.id
ORDER BY
	p.product_number
),
pieces as (
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

kit_qoh as (

SELECT 
  coalesce(p.edi_number, p.product_number) as kit_id, 
  p.description,
  sum (s.quantity_on_hand) as qoh
FROM 
  sms.stock s 
    left join sms.product p 
      on s.product_id = p.id
WHERE 
  s.inventory_type = 3 and s.location_type = 1 and s.stock_type in (3, 4)
GROUP BY 
  coalesce (p.edi_number, p.product_number), description
)


	
SELECT
	s2.kit_id,
	s2.kit_description,
	s2.component_prod_id,
	s2.component_description,
	s2.component_quantity_in_kit,
	s3.qoh
	--min(coalesce (s3.kit_qoh, 0)) over (partition by kit_id) as min_kits_avail_to_build
FROM
	s2
		LEFT JOIN Loaners.par_calculator_v2 l ON s2.kit_id = l.prod_id
		LEFT JOIN kit_qoh s3 ON s2.kit_description = s3.description
