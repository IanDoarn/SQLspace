SELECT
	p.id,
	p.product_number,
	p.edi_number,
	b.zone || '-' || b.position || '-' || b.shelf as bins
FROM
	sms.stock s
		LEFT JOIN sms.product p ON s.product_id = p.id
		LEFT JOIN sms.bin b ON b.id = s.container_id AND s.container_type = 1
WHERE
  s.inventory_type = 3
  and s.location_type = 1
  and s.container_type = 1
  and b.zone similar to 'R%'

GROUP BY
  p.id,
  bins,
  p.product_number,
  p.edi_number
ORDER BY 
	p.product_number,
	p.edi_number,
	bins