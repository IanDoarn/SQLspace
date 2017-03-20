with s1 as (
select
	'PKG' || '-' || pk.id as package_number,
	rank() over (partition by p.product_number) as pk_rank,
	pk.movement_id,
	m.id as movement_id_real,
	t.movement_id as transfer_movement_id,
	p.product_number,
	p.edi_number,
	p.description,
	t.serial_id,
	ps.serial_number,
	case
		when pk.status = 4 then 'SHIPPED'
		when pk.status = 3 then 'SHIPPING'
	end as status,
	case
		when pk.distributor_id = 168 then 'FROM SOUTHAVEN'
	end as from_location,

	to_char(pk.shipped_date, 'DD/MM/YYYY') as shipped_date,
	case
		when	pk.to_distributor_id = d.id then 'SHIPPED TO' || '-->' || d.city || ',' || d.state || ',' || d.country
	end as shipped_to,
	u.username
from
	sms.package pk
		LEFT JOIN sms.distributor d ON pk.to_distributor_id = d.id
		left join sms.movement m on pk.movement_id = m.id
		left join sms.transfer t on m.id = t.movement_id
		LEFT JOIN sms.product p ON p.id = t.product_id
		left join sms.product_serial ps on ps.id = t.serial_id
		LEFT JOIN sms.user_table u ON t.assigned_user_id = u.id
where
	pk.status in (3,4)
	AND pk.inventory_type = 3
	and pk.distributor_id = 168
	and pk.shipped_date > '2016-06-30'
Order by
	shipped_date desc
),
s3 as (
SELECT
	p.id,
	p.product_number,
	p.edi_number,
	p.description,
	ps.serial_number,
	s.serial_id,
	ps.id as product_serial_id,
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
	p.id,
	ps.id

ORDER BY
	p.product_number
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
 a1 as (
SELECT DISTINCT
	s.product_id,
	pc.component_product_id,
	pc.quantity
FROM
	sms.stock s
		LEFT JOIN sms.product_component pc ON s.product_id = pc.product_id
WHERE
	stock_type in (3, 4)
	AND inventory_type = 3
),
a2 as (
SELECT
	p.product_number as kit_product_number,
	p.edi_number as kit_edi,
	p.description as kit_description,
	p2.product_number as component_product_number,
	p2.edi_number as component_prod_id,
	p2.description as component_description,
	a1.quantity as component_quantity_in_kit,
	rank() over (partition by p.product_number) as rank
FROM
	a1
		LEFT JOIN sms.product p ON a1.product_id = p.id
		LEFT JOIN sms.product p2 ON a1.component_product_id = p2.id
WHERE
	p.product_number not like 'ZPB%'
group by
	p.product_number,
	p.edi_number,
	p.description,
	p2.product_number,
	p2.edi_number,
	p2.description,
	a1.quantity
order by
	p.product_number
),
a3 as (
SELECT
	a2.kit_product_number,
	count(a2.rank) as total_pieces_in_kit
FROM
	a2
group by
	a2.kit_product_number
order by
	a2.kit_product_number
),
a4 as (
select
	a3.kit_product_number,
	case when a3.total_pieces_in_kit is null then sum(s1.pk_rank) end as total
from
	a3
		left join s1 on s1.product_number = a3.kit_product_number
group by
	a3.kit_product_number,
	a3.total_pieces_in_kit
)
select
	s1.package_number,
	s1.transfer_movement_id as movement_id,
	s1.username as User_Name,
	s1.product_number as kit_and_part_number,
	s1.edi_number as kit_and_part_edi_number,
	s1.description as kit_and_part_description,
	s2.ri_bin,
	s1.serial_number,
	s3.g_bin,
	case
		when s1.serial_number is null then 'Loose Piece'
		else 'Kit'
	end as product_type,
	case
		when a3.total_pieces_in_kit > 0 then total_pieces_in_kit
		when a3.total_pieces_in_kit is null then sum(s1.pk_rank)
	end as total,
	s1.status,
	s1.from_location,
	s1.shipped_date,
	s1.shipped_to
from
	s1

		left join a3 on s1.product_number = a3.kit_product_number
		left join a4 on s1.product_number = a4.kit_product_number
		left join s2 on s1.product_number = s2.product_number and s1.edi_number = s2.edi_number
		left join s3 on s1.product_number = s3.product_number and s1.edi_number = s3.edi_number

group by
	s1.package_number,
	s1.transfer_movement_id,
	s1.username,
	s1.product_number,
	s1.edi_number,
	s1.description,
	s2.ri_bin,
	s1.serial_number,
	s3.g_bin,
	a3.total_pieces_in_kit,
	s1.status,
	s1.from_location,
	s1.shipped_date,
	s1.shipped_to,
	a4.total
order by
	s1.shipped_date