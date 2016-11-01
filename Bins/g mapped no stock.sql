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
  coalesce (s1.edi_number, s1.product_number) as kit_id,
  p.product_number,
  p.description
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
s1.product_number,
p.product_number,
p.description

)
SELECT 
	s2.product_number,
	s2.description,
	s2.bin,
	CASE
		WHEN count(bit_length(kit_id))  > 0 THEN 'NO'
		WHEN count(bit_length(kit_id)) = 0 THEN 'YES'
	END AS Empty
FROM 
	s2
WHERE
	s2.Kit_id is null
	and s2.bin not like 'D%'
GROUP BY
	s2.product_number,
	s2.description,
	s2.bin
ORDER BY
	s2.bin