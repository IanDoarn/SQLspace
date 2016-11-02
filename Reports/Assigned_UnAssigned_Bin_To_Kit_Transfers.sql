SET LOCAL timezone to 'PST8PDT';
with s1 as ( --Transfers Table, assigned and unassigned transfer for the past two
SELECT       --weeks to two weeks in the future. this Subquery shows Bin to Kit Transfers.
	t.movement_id,
	t.id as transfer_number,
	p.product_number,
	p.edi_number,
	p.description,
	to_char(created_date::timestamp at time zone '""Etc/GMT+3"', 'DD/MM/YYYY HH12:MI:SS PM') as created_date,
	CASE 
		WHEN t.from_container_type = 1 THEN 'FROM BIN'
		WHEN t.from_container_type = 2 THEN 'FROM KIT'
	END AS from_container_type,
	CASE
		WHEN t.to_container_type = 1 THEN 'INTO BIN'
		WHEN t.to_container_type = 2 THEN 'INTO KIT'
	END AS to_container_type,
	CASE 
		WHEN t.status = 0 THEN 'UNASSIGNED'
		WHEN t.status = 1 THEN 'ASSIGNED'
	END AS Status,
	t.assigned_user_id,
	t.to_kit_serial_id,
	to_kit_product_id
FROM
	sms.transfer t
		LEFT JOIN sms.product p ON p.id = t.product_id 
WHERE
	t.location_type = 1
	and t.location_id = 370
	and t.status in (0,1)
	and t.created_date between localtimestamp - interval '14 day' and timestamp 'today' + interval '14 days'
	and t.transfer_type = 1
),
s2 as ( -- Bin Locations for R and I bins using doarni.bins_v2 to map
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
s3 as ( -- Bin Locations for G bins using doarni.bins_v2 to map
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
),
s4 as (
SELECT
	t.assigned_user_id,
	u.username
FROM
	sms.transfer t
		JOIN sms.user_table u ON t.assigned_user_id = u.id
WHERE
	t.created_date between localtimestamp - interval '14 day' and timestamp 'today' + interval '14 days'
	and u.username not similar to '%TCI'
GROUP BY
	t.assigned_user_id,
	u.username
)
SELECT
	s1.transfer_number,
	s1.status,
	s4.username,
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
	s1.created_date
FROM
	s1
		LEFT JOIN s2 ON s1.product_number = s2.product_number AND s1.edi_number = s2.edi_number
		LEFT JOIN s3 ON s1.to_kit_product_id = s3.id AND s1.to_kit_serial_id = s3.serial_id
		FULL OUTER JOIN s4 ON s4.assigned_user_id = s1.assigned_user_id
ORDER BY
	s1.created_date
