Select 
  b.zone || '-' || b.position || '-' || b.shelf as bin,
  array_to_string(array_agg(p.product_number), ' , ') as product_number,
  array_to_string(array_agg(distinct Serial_number), ', ') as serials
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN sms.bin b ON b.id = s.container_id and s.container_type = 1
    LEFT JOIN sms.product_serial ps ON ps.id = s.serial_id
 WHERE
   s.location_type = 1 
   and s.location_id = 370
   and s.stock_type in (3,4)
   and s.container_type = 1

group by
p.product_number,
p.description,
bin

order by
p.product_number