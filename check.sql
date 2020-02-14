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

create or replace view sameplace as select ud1.userid uid1, ud2.userid uid2 from userdetails ud1, userdetails ud2 where ud1.place = ud2.place and ud1.userid <> ud2.userid;

create or replace view notsameplace as select *, array[userid1, userid2] tstep from (select * from tempq1 except select * from sameplace) temp;

create or replace view allconnected as select count(*) from (select * from tempq11 where (uid1 = 12 and uid2 = 14) or (uid1 = 12 and uid2 = 7) or (uid1 = 14 and uid2 = 7)) temp;
create or replace view ifconnected as select uid1, uid2 from tempq11, allconnected where uid1 = 12 and uid2 = 14 and count = 3;


create or replace view q8 as (with recursive testing(uid1, uid2, step) as(
	select userid1, userid2, array[userid1, userid2] as tstep from tempq1, ifconnected where userid1 = 12 and (userid1 = uid1 or userid1 = uid2)
	union
	select uid1, userid2, step||userid2 as step
	from testing, tempq1
	where userid1 = uid2  and not userid2 = any (step)
)select uid1, uid2, step from testing where uid2 = 14 and 7 = any (step));

--8--
select max(count) as count from (select uid1, uid2, count(*) from q8 group by uid1, uid2
union
select -1, -1, -1 as count where 3 not in (select * from allconnected)
union
select 0, 0, 0 as count where 3 in (select * from allconnected)) temp;
--CLEANUP--

-- drop view q7 cascade;
-- drop view dekhtehain cascade;
-- drop view nonblocked cascade;
-- drop view q9 cascade;
-- drop view q8 cascade;
-- drop view ifconnected910 cascade;
-- drop view ifconnected cascade;
-- drop view notsameplace cascade;
-- drop view scnddeg cascade;
-- drop view sameplace cascade;
-- drop view notincompo cascade;
-- drop view q3 cascade;
-- drop view blocked cascade;
-- drop view blockgrp cascade;
-- drop view blockletsfail cascade;
-- drop view blocktempq1 cascade;
-- drop view grp cascade;
-- drop view again cascade;
-- drop view letsfail cascade;
-- drop view ftempq1 cascade;
-- drop view tempq11 cascade;
-- drop view tempq1 cascade;
