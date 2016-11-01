SELECT
  p.product_number as kit_id, 
  p.edi_number, 
  p.description, 
  c.bin,
  r.serial_number 
FROM 
  sms.stock s
	LEFT JOIN sms.product p ON s.product_id = p.id
	LEFT JOIN sms.ci_inventory c ON c.prod_id = p.edi_number
	INNER JOIN sms.product_serial r ON s.product_id = r.product_id
WHERE
	inventory_type = 3
	and stock_type in (3, 4)
	and p.product_number not like 'ZPB%'
	--and c.bin not similar to 'New Kit%' 
	
	

group by
	p.product_number,
	p.edi_number, 
	p.description,
	c.bin,
	r.serial_number,
	stock_type
	
	
ORDER BY
	kit_id

LIMIT 1