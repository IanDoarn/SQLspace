with kit_par as (
-- Lists vital kit information from Loaners Kit Builder
SELECT
	kb.kit_id,
	kb.kit_description,
	kb.component_prod_id,
	kb.component_description,
	kb.component_quantity_in_kit,
	kb.kit_qoh,
	kb.loose_qoh,
	kb.min_kits_avail_to_build
FROM 
	loaners.kit_builder kb
WHERE
	kb.min_kits_avail_to_build > 0 AND kb.min_kits_avail_to_build is not null
	

ORDER BY
	kb.kit_id,
	kb.loose_qoh
),


pieces as (
-- Lists each piece
SELECT
	p.product_number,
	p.edi_number,
	b.zone || '-' || b.position || '-' || b.shelf as bin
FROM
	sms.stock s
		LEFT JOIN sms.product p ON s.product_id = p.id
		LEFT JOIN sms.bin b ON b.id = s.container_id and s.container_type = 1
WHERE
	s.inventory_type = 3
	and s.location_type = 1
	and s.container_type = 1
),

loose_in_whse as (
-- Shows how much of each component is loose in the warehouse
SELECT
	p.product_number,
	p.edi_number,
	sum(s.quantity_on_hand) AS qoh
FROM
	sms.stock s
		LEFT JOIN sms.product p ON p.id = s.product_id
WHERE
	s.inventory_type = 3
	AND s.location_type = 1
GROUP BY
	p.product_number,
	p.edi_number
),

kit_qoh as (
-- Finds the Qantity on Hand of each kit
SELECT 
  coalesce(p.edi_number, p.product_number) as edi_number, 
  p.description,
  sum (s.quantity_on_hand) as kit_qoh
FROM 
  sms.stock s 
    left join sms.product p 
      on s.product_id = p.id
WHERE 
  s.inventory_type = 3 
  and s.location_type = 1 
  and s.stock_type in (3, 4)
GROUP BY 
  coalesce (p.edi_number, p.product_number), description

)

SELECT DISTINCT
	s0.kit_id,
	s0.kit_description,
	s1.product_number,
	s0.component_prod_id,
	s0.component_description,
	s0.component_quantity_in_kit,
	s1.bin,
	s5.kit_qoh,
	s0.loose_qoh,
	s0.min_kits_avail_to_build
FROM
	kit_par s0
		LEFT JOIN pieces s1 ON s0.component_prod_id = s1.edi_number
		LEFT JOIN kit_qoh s5 ON s0.kit_description = s5.description
		
GROUP BY
	s0.kit_id,
	s0.kit_description,
	s1.product_number,
	s0.component_prod_id,
	s0.component_description,
	s0.component_quantity_in_kit,
	s1.bin,
	s5.kit_qoh,
	s0.loose_qoh,
	s0.min_kits_avail_to_build
