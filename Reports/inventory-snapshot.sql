with pieces as (
  SELECT DISTINCT
    p.product_number,
    p.edi_number
FROM 
  sms.stock s
    LEFT JOIN sms.product p ON p.id = s.product_id
WHERE
  s.inventory_type = 3
),
  
loose_in_whse as (
SELECT
  p.product_number,
  p.edi_number,
  sum(s.quantity_on_hand) as qoh
FROM
  sms.stock s
    LEFT JOIN sms.product p ON p.id = s.product_id
WHERE
  s.inventory_type = 3
  and s.stock_type = 1
  and s.location_type = 1
  and s.location_id = 370

GROUP BY
  p.product_number,
  p.edi_number),

par as (
SELECT
  l.kit_id,
  l.kit_description,
  l.component_prod_id,
  avg (l.add) over (partition by l.kit_id) as add,
  avg ((l.ADD * 11) + (3.09 * l.stddev)) over (partition by l.kit_id) as par
FROM
  loaners.kit_builder l)


SELECT
  s7.kit_id,
  s7.kit_description,
  s0.product_number,
  s0.edi_number,
  coalesce (sum (s1.qoh),0) as loose_whse

FROM
  pieces s0
    LEFT JOIN loose_in_whse s1 ON s0.product_number = s1.product_number and s0.edi_number = s1.edi_number
    LEFT JOIN par s7 ON s7.component_prod_id = s0.edi_number
GROUP BY
  s0.product_number,
  s0.edi_number,
  s7.kit_id,
  s7.kit_description,
  s7.add,
  s7.par
order by
s7.kit_id