DECLARE
  Return_window integer := 4;
  
with s1 as (
SELECT
  current_date as snapshot_date,
  d.dcs_warehouse,
  d.name as distributor,
  a.name as account_name,
  a.account_number,
  coalesce( sa.last_name, st.name) as Rep_name,
  sa2.last_name as Coverage_Rep,
  p.product_number,
  p.edi_number,
  p.description,
  pl.lot_number,
  ps.serial_number,
  s.container_id as case_number,
  date_trunc ('day', c.surgery_date) as surgery_date,
  (wd2.workday_index - wd.workday_index) - Return_window as bus_days_late,  --adjust this integer for number of days until late
  ((wd2.workday_index + 1) - wd3.workday_index ) as bus_days_this_month,  --do you keep the +1??
  case
    when   ((wd2.workday_index - wd.workday_index) - Return_window) <1 then 0   --adjust this integer for numbers of days until late
    else   ((wd2.workday_index - wd.workday_index) - Return_window) * 25  --adjust this integer for number of days until late and fee per day
      end as non_adjusted_Total_charge,
  case
    when ((wd2.workday_index - wd.workday_index) - Return_window) < 1 then 0
    when  ((wd2.workday_index + 1) - wd3.workday_index ) < ((wd2.workday_index - wd.workday_index) -Return_window) then ((wd2.workday_index + 1) - wd3.workday_index )*25
      else ((wd2.workday_index - wd.workday_index) - Return_window) * 25 end as non_adjusted_month_charge,
  l.max_charge
  FROM
  sms.stock s
    LEFT JOIN sms.product p ON p.id = s.product_id
    LEFT JOIN sms.account a ON s.location_type = 9 and s.location_id = a.id
    LEFT JOIN sms.distributor d ON d.id = a.distributor_id 
    LEFT JOIN sms.product_serial ps ON s.serial_id = ps.id
    LEFT JOIN sms.product_lot pl ON s.lot_id = pl.id
    LEFT JOIN sms.case_table c ON s.container_type = 4 and c.id = s.container_id
    LEFT JOIN sms.sales_associate sa ON c.sales_associate_id = sa.id
    LEFT JOIN sms.sales_associate sa2 ON c.coverage_associate_id = sa2.id
    LEFT JOIN sms.sales_team st ON c.sales_team_id = st.id
    LEFT JOIN util.work_days wd ON wd.cal_date = date_trunc ('day', c.surgery_date)
    LEFT JOIN util.work_days wd2 ON wd2.cal_date = current_date
    LEFT JOIN loaners.late_list_info l ON l.product_number = p.product_number    
    LEFT JOIN util.work_days wd3 ON wd3.cal_date = date_trunc ('month', current_date)
WHERE
  s.inventory_type = 3
  and s.container_type = 4
  and s.stock_type  in (1, 3, 4)
  and (location_type != 1 and Location_id != 370)),

s2 as (
SELECT
  s1.*,
  Case 
    when non_adjusted_total_charge < max_charge then non_adjusted_total_charge
      else max_charge end as Total_Adj_charge 
FROM
  s1)
SELECT
  s2.*,
   CASE 
    when Total_adj_charge = max_charge and bus_days_late > 9 then 'yes' 
      else 'no' end as Transfer_flag
FROM
  s2