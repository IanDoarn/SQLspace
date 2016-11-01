
with s1 as (
SELECT
	t.id	as transfer,
	p.product_number,
	p.edi_number,
	p.description,
	t.assigned_user_id,
	u.username,
	t.to_kit_serial_id,
	to_kit_product_id,
	movement_id
FROM
	sms.transfer t
		LEFT JOIN sms.product p ON p.id = t.product_id 
		LEFT JOIN sms.user_table u ON t.assigned_user_id = u.id
WHERE
	t.location_type = 1
	and t.location_id = 370
	and t.status in (1,2)
	and t.transfer_type = 1
),
s3 as (
SELECT
	p.id,
  p.product_number,
  p.edi_number,
  p.description,
  ps.serial_number,
  s.serial_id,
	d.zone || '-' || d.position || '-' || d.shelf as g_bin
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN bins_v2 d on d.bin_id = s.container_id and s.container_type = 1
    LEFT JOIN sms.product_serial ps on ps.id = s.serial_id
WHERE
  s.stock_type in (3,4)
  AND s.distributor_id =168
  and s.inventory_type = 3
  and s.location_type = 1
  and s.container_type = 1
  and d.zone similar to 'G%'

GROUP BY
  g_bin,
  p.product_number,
  p.edi_number,
  p.description,
  ps.serial_number,
  s.serial_id,
  p.id

ORDER BY 
	p.product_number
),
s6 as (
select
	'PKG' || '-' || pk.id as package_number,
	movement_id,
	case
		when pk.status = 4 then 'SHIPPED' 
		when pk.status = 3 then 'SHIPPING'
	end as status,
	case
		when pk.distributor_id = 168 then 'FROM SOUTHAVEN' 
	end as from_location,
	
	to_char(pk.shipped_date, 'YYYY-MM-DD') as shipped_date,
	case
		when	pk.to_distributor_id = d.id then 'SHIPPED TO' || '-->' || d.city || ',' || d.state || ',' || d.country
	end as shipped_to
from
	sms.package pk
		LEFT JOIN sms.distributor d ON pk.to_distributor_id = d.id
where
	pk.status in (3,4)
	AND pk.inventory_type = 3
	and pk.distributor_id = 168
	and pk.shipped_date between '2016-06-01' and '2016-07-01'
Order by
	shipped_date desc
)

SELECT
	s6.movement_id as movement_number,
	s6.package_number,
	s1.transfer,
	s1.username,
	s1.assigned_user_id,
	s1.product_number,
	s1.edi_number,
	s1.description,
	s3.product_number,
	s3.description,
	s3.serial_number,
	s3.g_bin,
	s6.from_location,
	s6.shipped_date,
	s6.shipped_to
FROM
	s6
		left join s1 on s6.movement_id = s6.movement_id
		LEFT JOIN s3 ON s1.to_kit_product_id = s3.id AND s1.to_kit_serial_id = s3.serial_id
order by
	s6.shipped_date