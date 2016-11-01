with s1 as (
SELECT
	p.product_number,
	p.edi_number,
	c.bin,
	r.serial_number,
	CASE
		WHEN container_type = 1 THEN to_char(1, '"BIN"')
		WHEN container_type = 2 THEN to_char(2, '"KIT"')
		WHEN container_type = 3 THEN to_char(3, '"PACKAGE"')
		WHEN container_type = 4 THEN to_char(4, '"LOAN"')
	END AS CONTAINER_TYPE

FROM
	sms.stock s
		LEFT JOIN sms.product p ON s.product_id = p.id
		LEFT JOIN sms.ci_inventory c ON c.prod_id = p.edi_number
		LEFT JOIN sms.product_serial r ON r.product_id = s.product_id
WHERE
	inventory_type = 3
	and stock_type in (3, 4)
	--and c.bin not like ''
	and p.product_number not like 'ZPB%'
	and p.product_number is not null
	

GROUP BY
	p.product_number,
	p.edi_number,
	r.serial_number,
	c.bin,
	s.stock_type,
	s.container_type

	

ORDER BY
	p.product_number,
	c.bin,
	r.serial_number),

s2 as (
 DELETE FROM
 s1
 WHERE
 

LIMIT 100;
