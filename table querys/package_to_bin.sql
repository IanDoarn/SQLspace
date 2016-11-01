SET LOCAL timezone to 'PST8PDT';
with s1 as (
SELECT
	t.id	as transfer,
	p.product_number,
	p.edi_number,
	p.description,
	t.movement_id as transfer_movement_id,
  to_char(completed_date::timestamp at time zone '""Etc/GMT+3"', 'DD/MM/YYYY HH12:MI:SS PM') as completed_date,
	CASE 
		WHEN t.from_container_type = 1 THEN 'From Vehicle/bin'
		when t.from_container_type = 3 then 'from Package'
	END AS from_container_type,
	CASE
		WHEN t.to_container_type = 1 THEN 'Into Bin'
	END AS to_container_type,
	CASE 
		WHEN t.status = 2 THEN 'COMPLETE'
	END AS Status,
	t.assigned_user_id,
	u.username,
	t.to_kit_serial_id,
	d.zone || '-' || d.position || '-' || d.shelf as g_bin
FROM
	sms.transfer t
		LEFT JOIN sms.user_table u ON t.assigned_user_id = u.id
		LEFT JOIN sms.product p ON p.id = t.product_id 
		LEFT JOIN doarni.bins_v2 d on d.product_number = p.product_number
WHERE
	t.location_type = 1
	and t.location_id = 370
	and t.status in (1,2)
	and t.completed_date between '2016-07-01' and '2016-07-30'
	--and t.completed_date >= TIMESTAMP 'yesterday'
	--AND t.completed_date < TIMESTAMP 'today'
	and t.transfer_type = 17
),
s2 as (
select
	t.id as transfer_num,
	'PKG' || '-' || pk.id as package_number,
	pk.movement_id,
	t.movement_id as transfer_movement_id
from
	sms.package pk
		left join sms.movement m on pk.movement_id = m.id
		left join sms.transfer t on m.id = t.movement_id
where
	pk.status in (3,4)
	AND pk.inventory_type = 3
	and pk.distributor_id = 168
	and pk.shipped_date > '2016-06-30'
Order by
	pk.shipped_date
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
    LEFT JOIN doarni.bins_v2 d on d.product_number = p.product_number
    LEFT JOIN sms.product_serial ps on ps.id = s.serial_id
WHERE
  s.stock_type in (3,4)
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
)

select
	s1.transfer,
	s1.status,
	s1.username,
	s1.product_number,
	s1.edi_number,
	s1.description,
	s1.from_container_type,
	s1.to_container_type,
	s1.g_bin,
	s1.completed_date
FROM
	s1
		left join s2 on s1.transfer = s2.transfer_num
order by
	s1.completed_date desc;
