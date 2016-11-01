With a1 as (  
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
  ),
a2 as (
SELECT
  p.product_number as kit_product_number, 
  p.edi_number as kit_edi,  
  p.description as kit_description,
  p2.product_number as component_product_number,
  p2.edi_number as component_prod_id,
  p2.description as component_description,
  a1.quantity as component_quantity_in_kit,
  rank() over (partition by p.product_number) as rank
FROM 
  a1
    LEFT JOIN sms.product p ON a1.product_id = p.id
    LEFT JOIN sms.product p2 ON a1.component_product_id = p2.id
WHERE 
  p.product_number not like 'ZPB%'
group by
  p.product_number,
  p.edi_number,
  p.description,
  p2.product_number,
  p2.edi_number,
  p2.description,
  a1.quantity
order by
  p.product_number
)
SELECT
	a2.kit_product_number,
	count(a2.rank) as total_pieces_in_kit
FROM
	a2
group by
	a2.kit_product_number
order by
	a2.kit_product_number