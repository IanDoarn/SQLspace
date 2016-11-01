SELECT
  p.id,
  p.product_number,
  p.edi_number,
  ps.serial_number,
	d.zone || '-' || d.position || '-' || d.shelf as bins
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN bins_v2 d on d.bin_id = s.container_id and s.container_type = 1
    LEFT JOIN sms.product_serial ps on ps.id = s.serial_id
WHERE
  s.stock_type in (3,4)
  and s.inventory_type = 3
  and s.location_type = 1
  and s.distributor_id = 168
  and s.container_type = 1
  and d.zone similar to 'G%'

GROUP BY
  p.id,
  bins,
  p.product_number,
  p.edi_number,
  ps.serial_number

ORDER BY 
	p.product_number,
	ps.serial_number,
	p.edi_number,
	bins