SELECT
	p.product_number,
	p.edi_number,
	p.description,
	d.zone || '-' || d.position || '-' || d.shelf as component_bin
FROM
	sms.product p
		LEFT JOIN bins_v2 d on d.product_number = p.product_number
		--left join sms.bin

WHERE
	d.zone similar to '%(R|I)%'
	

GROUP BY
	component_bin,
	p.product_number,
	p.edi_number,
	p.description

order by
	p.product_number
