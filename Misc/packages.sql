select
	'PKG' || '-' || pk.id as package_number,
	rank() over (partition by pk.id) as pk_rank,
	pk.movement_id,
	m.id as movement_id_real,
	t.movement_id as transfer_movement_id,
	p.product_number,
	p.edi_number,
	p.description,
	--ps.serial_number,
	--2.pl.lot_number,
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
	end as shipped_to
from
	sms.package pk
		LEFT JOIN sms.distributor d ON pk.to_distributor_id = d.id
		left join sms.movement m on pk.movement_id = m.id
		left join sms.transfer t on m.id = t.movement_id
		LEFT JOIN sms.product p ON p.id = t.product_id 
		left join sms.product_serial ps on ps.id = t.serial_id
		--left join sms.product_lot pl on pl.product_id = p.id 
where
	pk.status in (3,4)
	AND pk.inventory_type = 3
	and pk.distributor_id = 168
	and pk.shipped_date > '2016-06-24'
Order by
	shipped_date desc