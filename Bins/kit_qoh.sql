with s1 as (
SELECT
  p.product_number,
  p.edi_number,
  b.zone || '-' || b.position || '-' || b.shelf as component_bin,
  sum (s.quantity_available) as Qty_avail_SH
FROM
  sms.stock s
    LEFT JOIN sms.product p ON p.id = s.product_id
    LEFT JOIN sms.bin b ON b.id = s.container_id and s.container_type = 1
WHERE
  s.stock_type = 1
  and s.inventory_type = 3
  and s.location_type = 1
  and s.location_id = 370
  and s.container_type = 1
  and s.quantity_available > 0
  and b.zone like 'R%'
GROUP BY
  p.product_number,
  p.edi_number,
  b.zone || '-' || b.position || '-' || b.shelf
) 

SELECT
	s1.*,
	row_number() over (partition by s1.product_number)
FROM
	s1
ORDER BY
  s1.component_bin,
  s1.product_number,
  s1.edi_number