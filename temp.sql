with recursive t(account_id, device_id) as (
       select 1, 10 union all
       select 1, 11 union all
       select 1, 12 union all
       select 2, 10 union all
       select 3, 11 union all
       select 3, 13 union all
       select 3, 14 union all
       select 4, 15 union all
       select 5, 15 union all
       select 6, 16
     ),
     a as (
      select distinct t.account_id as a, t2.account_id as a2
      from t join
           t t2
           on t2.device_id = t.device_id and t.account_id >= t2.account_id
     ),
     cte as (
      select a.a, a.a2 as mina
      from a
      union all
      select a.a, cte.a
      from cte join
           a
           on a.a2 = cte.a and a.a > cte.a
     )
select grp, array_agg(a)
from (select a, min(mina) as grp
      from cte
      group by a
     ) a
group by grp;
