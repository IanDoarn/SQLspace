SET LOCAL timezone to 'PST8PDT';
with s1 as (

SELECT
	t.movement_id,
	t.id	as transfer,
	p.product_number,
	p.edi_number,
	p.description,
  to_char(completed_date::timestamp at time zone '""Etc/GMT+3"', 'DD/MM/YYYY HH12:MI:SS PM') as completed_date,
	CASE 
		WHEN t.from_container_type = 1 THEN 'From Bin'
		WHEN t.from_container_type = 2 THEN 'From Kit'
	END AS from_container_type,
	CASE
		WHEN t.to_container_type = 1 THEN 'Into Bin'
		WHEN t.to_container_type = 2 THEN 'Into Kit'
	END AS to_container_type,
	CASE 
		WHEN t.status = 1 THEN 'ASSIGNED'
		WHEN t.status = 2 THEN 'COMPLETE'
	END AS Status,
	t.assigned_user_id,
	u.username,
	t.to_kit_serial_id,
	to_kit_product_id
FROM
	sms.transfer t
		LEFT JOIN sms.product p ON p.id = t.product_id 
		LEFT JOIN sms.user_table u ON t.assigned_user_id = u.id
WHERE
	t.location_type = 1
	and t.location_id = 370
	and t.status = 1
        and t.completed_date between '2016-10-29' and '2016-10-31'
	--and t.completed_date >= TIMESTAMP 'yesterday'
	--AND t.completed_date < TIMESTAMP 'today'
	and t.transfer_type = 1
),
s2 as (
SELECT
  p.product_number,
  p.edi_number,
  d.zone || '-' || d.position || '-' || d.shelf as ri_bin
FROM
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN doarni.bins_v2 d on d.product_number = p.product_number
WHERE
  d.zone similar to '%(R|I)%'

GROUP BY
  ri_bin,
  p.product_number,
  p.edi_number

ORDER BY 
	p.product_number
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
SELECT
	s1.transfer,
	s1.status,
	s1.username,
	s1.assigned_user_id,
	s1.product_number,
	s1.edi_number,
	s1.description,
	s1.from_container_type,
	s2.ri_bin,
	s1.to_container_type,
	s3.product_number,
	s3.description,
	s3.serial_number,
	s3.g_bin,
	s1.completed_date
FROM
	s1
		LEFT JOIN s2 ON s1.product_number = s2.product_number AND s1.edi_number = s2.edi_number
		LEFT JOIN s3 ON s1.to_kit_product_id = s3.id AND s1.to_kit_serial_id = s3.serial_id
order by
	s1.completed_date
