SELECT
  p.product_number,
  p.edi_number,
  ps.serial_number,
	d.zone || '-' || d.position || '-' || d.shelf as g_bin
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN bins d on d.bin_id = s.container_id and s.container_type = 1
    LEFT JOIN sms.product_serial ps on ps.id = s.serial_id
WHERE
  s.stock_type in (3,4)
  and s.inventory_type = 3
  and s.location_type = 1
  and s.location_id = 370
  and s.container_type = 1
  and d.zone similar to 'G%'

GROUP BY
  g_bin,
  p.product_number,
  p.edi_number,
  ps.serial_number

ORDER BY 
	p.product_number