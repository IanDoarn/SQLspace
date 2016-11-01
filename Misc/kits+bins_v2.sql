with s1 as (
SELECT 
  p.product_number, p.edi_number, p.description, c.bin,
	case when stock_type = 3 then sum(s.quantity_on_hand) end as Valid,
	case when stock_type = 4 then sum(s.quantity_on_hand) end as Invalid
FROM 
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
    LEFT JOIN sms.ci_inventory c ON c.stock_id = s.id
WHERE
  s.inventory_type = 3
  and s.location_type = 1
  and stock_type in (3,4)
group by
  p.product_number,p.edi_number, p.description, c.bin,
  s.stock_type),

s2 as (
Select
  s1.product_number, s1.edi_number, s1.description, s1.bin,
  coalesce(sum(s1.valid),0) as valid,
  coalesce(sum (s1.invalid),0) as invalid,
  case 
    when sum(s1.valid) is null then 1.0
    when sum(s1.invalid) is null then 0.0
      else sum(s1.invalid)/   (sum(s1.valid)+ sum (s1.invalid)) end as Kits_on_hand
from
 s1
Group by 
  product_number, edi_number, description, bin)
SELECT
  s2.* 
from
  s2
Order by
Kits_on_hand