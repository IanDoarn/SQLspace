with s1 as (
SELECT
	p.edi_number, 
	p.product_number
FROM
	sms.product p
),

s2 as (
Select
  b.zone || '-' || b.position || '-' || b.shelf as bin,
  coalesce (s1.edi_number, s1.product_number) as kit_id
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN sms.bin b ON b.id = s.container_id
    LEFT JOIN s1 ON p.product_number = s1.product_number AND p.edi_number = s1.edi_number
 WHERE
   s.location_type = 1 
   and s.location_id = 370
   and s.stock_type in (3,4)
   and s.container_type = 1

group by
bin,
s1.edi_number,
s1.product_number

)
SELECT 
	s2.bin,
	array_to_string(array_agg(s2.kit_id) , ', ') as Kit_id
	
	
FROM 
	s2
GROUP BY
	s2.bin
ORDER BY
	s2.bin