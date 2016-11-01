with s1 as (
SELECT 
  date_trunc ('day', shipped_date) :: date as shipped_Date, 
  prod_id, 
  qty_out as Kits_shipped_Qty
FROM 
  sms.ci_order_line_summary
where 
  shipped_date > current_date - interval '4 week'
  and prod_id like '57_________'),

s2 as (
SELECT
  Shipped_Date,
  prod_id,
  sum (Kits_Shipped_qty) as Prod_kits_qty_out

From 
  s1
GROUP BY
  Shipped_Date,
  prod_id),
s3 as (
SELECT
  s2.shipped_date,
  s2.prod_id,
  d.child_prod_id,
  s2.prod_kits_qty_out,
  s2.Prod_kits_qty_out * d.child_prod_per_parent_qty as units_shipped
  
FROM
  s2
    LEFT JOIN dcs.prod_kit_component d  
      ON s2.prod_id = d.prod_id and d.warehouse_id = '5C'),
s4 as(
SELECT
  shipped_date,
  prod_id,
  prod_kits_qty_out,
  sum (units_shipped) as qty
FROM
  s3
Group By
  shipped_date,
  prod_id,
  prod_kits_qty_out
ORDER BY 
  shipped_Date )

Select
  Shipped_date,
  sum (Prod_kits_qty_out) as kits_shipped,
  Sum (qty) as units_shipped_in_kits
From
  s4
group By
  shipped_Date 
order by shipped_Date desc