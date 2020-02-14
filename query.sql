--PREAMBLE--
create or replace view tempq1(userid1, userid2) as
	select * from friendlist
	union
	select userid2, userid1 from friendlist;

create or replace view tempq11(uid1, uid2) as
	with recursive test(uid1, uid2) as(
		select * from tempq1
		union
		select tempq1.userid1, test.uid2
		from tempq1, test
		where tempq1.userid2 = test.uid1
	)select * from test;

create or replace view ftempq1(uid1, uid2) as
	select * from tempq11
	union
	select userid as uid1, userid as uid2
	from userdetails
	where userid not in (select distinct(uid1) from tempq11);

create or replace view letsfail as
	select uid1, count(uid1)
	from ftempq1
	group by uid1;

create or replace view grp as
	select uid1, array_agg(uid2)
	from ftempq1
	group by uid1
	order by uid1;

create or replace view blocktempq1(uid1, uid2) as
	select * from block
	union
	select userid2, userid1 from block;

create or replace view blockletsfail as
	select uid1, count(uid1)
	from blocktempq1
	group by uid1;

create or replace view blockgrp as
	select uid1, array_agg(uid2)
	from blocktempq1
	group by uid1
	order by uid1;

create or replace view blocked as
	select tempq11.uid1, tempq11.uid2
	from tempq11, blocktempq1
	where tempq11.uid1 = blocktempq1.uid1 and tempq11.uid2 = blocktempq1.uid2;

create or replace view q3 as (
	select uid1, count(uid2)
	from blocked
	group by uid1);

create or replace view notincompo as
	((select ud1.userid as uid1, ud2.userid as uid2
		from userdetails ud1, userdetails ud2
		where ud1.userid <> ud2.userid
	except
	select * from ftempq1)
	except
	select * from blocktempq1);

create or replace view sameplace as select ud1.userid uid1, ud2.userid uid2 from userdetails ud1, userdetails ud2 where ud1.place = ud2.place and ud1.userid <> ud2.userid;

create or replace view scnddeg as
	select tq1.userid1, tq2.userid2
	from tempq1 tq1, tempq1 tq2
	where tq1.userid2 = tq2.userid1 and tq1.userid1 <> tq2.userid2
	except
	select * from tempq1;

create or replace view notsameplace as select *, array[userid1, userid2] tstep from (select * from tempq1 except select * from sameplace) temp;

create or replace view allconnected as select count(*) from (select * from tempq11 where (uid1 = 3552 and uid2 = 1436) or (uid1 = 3552 and uid2 = 321) or (uid1 = 1436 and uid2 = 321)) temp;

create or replace view ifconnected as select uid1, uid2 from tempq11, allconnected where uid1 = 3552 and uid2 = 1436 and count = 3;

create or replace view ifconnected910 as select * from tempq11 where uid1 = 3552 and uid2 = 321;

create or replace view q8 as (with recursive testing(uid1, uid2, step) as(
	select userid1, userid2, array[userid1, userid2] as tstep from tempq1, ifconnected where userid1 = 3552 and (userid1 = uid1 or userid1 = uid2)
	union
	select uid1, userid2, step||userid2 as step
	from testing, tempq1
	where userid1 = uid2  and not userid2 = any (step)
)select uid1, uid2, step from testing where uid2 = 1436 and 321 = any (step));

create or replace view q9 as (with recursive testing(uid1, uid2, step) as(
	select userid1, userid2, tstep
	from notsameplace, ifconnected910
	where userid1 = 3552 and (userid1 = uid1 or userid1 = uid2)
	union
	select uid1, userid2, step||userid2 as step
	from testing, notsameplace
	where userid1 = uid2 and not userid2 = any (step)
)select uid1, uid2, step from testing where uid2 = 321);

create or replace view nonblocked as select * from tempq1 except select * from blocktempq1;

create or replace view dekhtehain as (select * from (with recursive testing(uid1, uid2, step) as(
	select userid1, userid2, array[userid1, userid2] from nonblocked, ifconnected910 where userid1 = 3552 and (userid1 = uid1 or userid2 = uid2)
	union
	select uid1, userid2, step||userid2 as step
	from testing, nonblocked
	where userid1 = uid2 and not userid2 = any (step)
)select uid1, uid2, step from testing) temp);

create or replace view q7 as with recursive testing(uid1, uid2, step) as(
	select *, array[userid1, userid2] as tstep from tempq1
	union
	select uid1, userid2, step||userid2 as step
	from testing, tempq1
	where userid1 = uid2 and array_length(step, 1) <= 3 and not userid2 = any (step)
) select uid1, uid2, array_length(step, 1) as len from testing;

--1--
select sum(count/number) as count from (select count(*) as count, count as number from letsfail group by count) as tempq1;
--2--
select count(*) as count from grp group by array_agg order by count;
--3--
select uid1 as userid, count from q3 where count = (select max(count) from q3) order by userid;
--4--
with lentest as
(with recursive testing(uid1, uid2, step) as(
	select *, array[userid1, userid2] as tstep from tempq1 where userid1 = 1558
	union
	select uid1, userid2, step||userid2 as step
	from testing, tempq1
	where userid1 = uid2  and not userid2 = any (step)
)select min(array_length(step, 1))-1 as length from testing where  uid2 = 2826 group by uid1, uid2
union
select -1 as length) select max(length) as length from lentest;
--5--
with possiblefriendreq as
	((select * from ftempq1
	except
	select * from blocktempq1)
	except
	select * from tempq1)
select count(*)-1 as count from possiblefriendreq group by uid1 having uid1 = 704;
--6--
select uid1 as userid
from (select n.uid1, n.uid2
	from notincompo n, sameplace s
	where n.uid1 = s.uid1 and n.uid2 = s.uid2) temp
group by uid1
order by count(uid1) desc, uid1;
--7--

select uid1 as userid
from (select uid1, uid2
	from q7
	group by uid1, uid2 having min(len) = 4) temp
	group by uid1
	order by count(uid1) desc, uid1 limit 10;

--8--
select max(count) as count from (select uid1, uid2, count(*) from q8 group by uid1, uid2
union
select -1, -1, -1 as count where 3 not in (select * from allconnected)
union
select 0, 0, 0 as count where 3 in (select * from allconnected)) temp;
--9--
select max(count) as count from (select uid1, uid2, count(step) from q9 group by uid1, uid2
union
select 0, 0, 0 as count where (3552, 321) in (select * from ifconnected910)
union
select -1, -1, -1 as count where (3552, 321) not in (select * from ifconnected910)) temp;
--10--
select max(count) as count
from (select uid1, uid2, count(*)
		from dekhtehain
		where uid2 = 321 and (uid1, uid2, step) not in (select d1.uid1, d1.uid2, d1.step
				from dekhtehain d1, blocktempq1 b1
				where b1.uid1 = any(d1.step) and b1.uid2 = any(d1.step)) group by uid1, uid2
	union
	select -1, -1, -1 as count where (3552, 321) not in (select * from ifconnected910)
	union
	select 0, 0, 0 as count where (3552, 321) in (select * from ifconnected910)) temp;
--CLEANUP--

drop view dekhtehain cascade;
drop view nonblocked cascade;
drop view q9 cascade;
drop view q8 cascade;
drop view q7 cascade;
drop view ifconnected910 cascade;
drop view ifconnected cascade;
drop view allconnected cascade;
drop view notsameplace cascade;
drop view scnddeg cascade;
drop view sameplace cascade;
drop view notincompo cascade;
drop view q3 cascade;
drop view blocked cascade;
drop view blockgrp cascade;
drop view blockletsfail cascade;
drop view blocktempq1 cascade;
drop view grp cascade;
drop view letsfail cascade;
drop view ftempq1 cascade;
drop view tempq11 cascade;
drop view tempq1 cascade;
