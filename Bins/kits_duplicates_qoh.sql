with s1 as (
SELECT
p.product_number,
p.edi_number,
b.zone || '-' || b.position || '-' || b.shelf as kit_bin,
sum (s.quantity_available) as Qty_avail_SH
FROM
sms.stock s
LEFT JOIN sms.product p ON p.id = s.product_id
LEFT JOIN sms.bin b ON b.id = s.container_id and s.container_type = 1
WHERE
s.stock_type in (3, 4)
and s.inventory_type = 3
and s.location_type = 1
and s.location_id = 370
and s.container_type = 1
and s.quantity_available > 0
and b.zone like 'G%'
GROUP BY
p.product_number,
p.edi_number,
b.zone || '-' || b.position || '-' || b.shelf
),

s2 as (
SELECT
s1.*,
row_number() over (partition by s1.product_number)
FROM
s1
ORDER BY
s1.kit_bin,
s1.product_number,
s1.edi_number)

SELECT
s2.product_number,
s2.edi_number,
s1.kit_bin
FROM
s2
LEFT JOIN s1 on s1.product_number = s2.product_number
WHERE
s2.row_number = 2
Order By
s2.product_number
