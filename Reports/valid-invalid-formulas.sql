with s1 as (
SELECT 
  p.product_number, p.edi_number, p.description,
  case when stock_type = 3 then sum(s.quantity_on_hand) end as Valid,
  case when stock_type = 4 then sum(s.quantity_on_hand) end as Invalid
FROM 
  sms.stock s
    LEFT JOIN sms.product p ON s.product_id = p.id
WHERE
  s.inventory_type = 3
  and stock_type in (3,4)
group by
  p.product_number,p.edi_number, p.description,
  s.stock_type),

s2 as (
Select
  s1.product_number, s1.edi_number, s1.description, 
  coalesce(sum(s1.valid),0) as valid,
  coalesce(sum (s1.invalid),0) as invalid

from
 s1
Group by 
  product_number, edi_number, description)
SELECT
  s2.* 
from
  s2
