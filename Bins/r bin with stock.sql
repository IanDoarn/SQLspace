
SELECT
  p.id,
  p.product_number,
  p.edi_number,
  p.description,
  b.zone || '-' || b.position || '-' || b.shelf as component_bin
FROM
  sms.stock s
    LEFT JOIN sms.product p ON p.id = s.product_id
    LEFT JOIN sms.bin b ON b.id = s.container_id and s.container_type = 1
WHERE
  s.stock_type in (1,2)
  and s.inventory_type = 3
  and s.location_type = 1
  and s.location_id = 370
  and s.container_type = 1
  and b.zone similar to '%(R|I)%'

GROUP BY
  component_bin,
  p.product_number,
  p.edi_number,
  p.description,
  p.id
