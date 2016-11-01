Select 
  p.product_number,
	p.edi_number,
	d.zone || '-' || d.position || '-' || d.shelf as bin
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN bins d on d.id = s.product_id
 WHERE
   s.location_type = 1 
   and s.location_id = 370
   and s.container_type = 1

group by

  p.product_number,

	p.edi_number,

	bin


order by
p.product_number