with s1 as (
SELECT
  b.zone || '-' || b.position || '-' || b.shelf as component_bin,
  array_to_string(array_agg(distinct p.product_number), ',') as product_number

FROM
  sms.stock s
    LEFT JOIN sms.product p ON p.id = s.product_id
    LEFT JOIN sms.bin b ON b.id = s.container_id and s.container_type = 1
WHERE
  s.stock_type in (1,2,3,4)
  and s.inventory_type = 3
  and s.location_type = 1
  and s.location_id = 370
  and s.container_type = 1
  and b.zone similar to '%(R|I|G)%'

GROUP BY
  component_bin
  )


SELECT
	array_to_string(array_agg(s1.component_bin) , ', ') as R_I_G_BINS,
	CASE
		WHEN count(bit_length(Product_number))  > 0 THEN 'NO'
		WHEN count(bit_length(Product_number)) = 0 THEN 'YES'
	END AS Empty,
	CASE
		WHEN count(bit_length(Product_number)) != 0 THEN 'YES'
		WHEN count(bit_length(Product_number)) <= 0 THEN 'NO'
	END AS Mapped,
	CASE
		WHEN sum(length(Product_number)) <= 14 THEN 'NO'
		WHEN sum(length(Product_number)) is null THEN 'NO'
		WHEN sum(length(Product_number)) > 14 THEN 'YES'
	END AS Mixed,
	s1.product_number as Product_number
FROM
	s1
group by
	s1.product_number

order by
	R_I_G_BINS