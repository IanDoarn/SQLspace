with s1 as (
select
	'PKG' || '-' || pk.id as package_number,
	pk.tracking_number,
	pk.movement_id,
	m.id as movement_id_real,
	t.movement_id as transfer_movement_id,
	case
		when pk.status = 4 then 'SHIPPED' 
		when pk.status = 3 then 'SHIPPING'
	end as status,
	case
		when m.from_location_id = 370 then 'FROM SOUTHAVEN' 
	end as from_location,
	
	to_char(pk.shipped_date, 'DD/MM/YYYY') as shipped_date,
	case
		when	pk.to_distributor_id = d.id then 'SHIPPED TO' || d.city || ',' || d.state || ',' || d.postal_code || ',' || d.country
	end as shipped_to
from
	sms.package pk
		LEFT JOIN sms.distributor d ON pk.to_distributor_id = d.id
		left join sms.movement m on pk.movement_id = m.id
		left join sms.transfer t on m.id = t.movement_id
where
	pk.status in (3,4)
	AND pk.inventory_type = 3
	and pk.distributor_id = 168
	and pk.shipped_date between localtimestamp - interval '7 day' and timestamp 'today'
	and m.from_location_id = 370
Order by
	shipped_date desc
)
select
	s1.movement_id_real as movement_id,
	s1.shipped_date,
	s1.from_location,
	s1.shipped_to,
	s1.package_number,
	s1.tracking_number
from
	s1
Group by
	s1.movement_id_real,
	s1.shipped_date,
	s1.from_location,
	s1.shipped_to,
	s1.package_number,
	s1.tracking_number
order by
	s1.shipped_date
