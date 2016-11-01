SELECT 
  p2.product_number as kit_prod_number,
  p2.edi_number as kit_edi,
  p2.description as kit_description,
  ps.serial_number,
  b.zone || '-' || b.position || '-' || b.shelf as kit_bin,
  p.product_number as Component_product_number,
  p.edi_number as component_edi,
  p.description as component_description,
  sum (s.quantity_available) as quantity_available
FROM
  sms.stock s 
  LEFT JOIN sms.product p on s.product_id = p.id
  LEFT JOIN sms.stock s2 On s.container_id = s2.id and s.container_type = 2
  LEFT JOIN sms.product p2 on s2.product_id = p2.id
  left join sms.product_serial ps on s2.serial_id = ps.id
  LEFT JOIN sms.bin b on s2.container_id = b.id and s2.container_type = 1
where 
  s.location_type = 1
  and s.location_id = 370
  and s.stock_type = 2
  and s.container_type =2
  and p2.product_number is not null
GROUP BY
  p2.product_number ,
  p2.edi_number,
  p2.description,
  ps.serial_number,
  b.zone || '-' || b.position || '-' || b.shelf ,
  p.product_number ,
  p.edi_number ,
  p.description