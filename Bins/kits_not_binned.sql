Select 
  p.product_number,
  p.description,
  p.edi_number,
  b.zone || '-' || b.position || '-' || b.shelf as bin,
  CASE WHEN b.zone || '-' || b.position || '-' || b.shelf is null THEN 'NO BIN' END AS has_bin
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN sms.bin b ON b.id = s.container_id and s.container_type = 1
 WHERE
   s.location_type = 1 
   and s.location_id = 370
   and s.stock_type in (3,4)
   and s.container_type = 1
   and b.zone || '-' || b.position || '-' || b.shelf is null

group by
p.product_number,
p.description,
p.edi_number,
bin

order by
p.product_number