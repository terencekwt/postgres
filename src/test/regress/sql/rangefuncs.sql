SELECT name, setting FROM pg_settings WHERE name LIKE 'enable%';

CREATE TABLE foo2(fooid int, f2 int);
INSERT INTO foo2 VALUES(1, 11);
INSERT INTO foo2 VALUES(2, 22);
INSERT INTO foo2 VALUES(1, 111);

CREATE FUNCTION foot(int) returns setof foo2 as 'SELECT * FROM foo2 WHERE fooid = $1 ORDER BY f2;' LANGUAGE SQL;

-- function with ORDINALITY
select * from foot(1) with ordinality as z(a,b,ord);
select * from foot(1) with ordinality as z(a,b,ord) where b > 100;   -- ordinal 2, not 1
-- ordinality vs. column names and types
select a,b,ord from foot(1) with ordinality as z(a,b,ord);
select a,ord from unnest(array['a','b']) with ordinality as z(a,ord);
select * from unnest(array['a','b']) with ordinality as z(a,ord);
select a,ord from unnest(array[1.0::float8]) with ordinality as z(a,ord);
select * from unnest(array[1.0::float8]) with ordinality as z(a,ord);
-- ordinality vs. views
create temporary view vw_ord as select * from (values (1)) v(n) join foot(1) with ordinality as z(a,b,ord) on (n=ord);
select * from vw_ord;
select definition from pg_views where viewname='vw_ord';
drop view vw_ord;
-- ordinality vs. rewind and reverse scan
begin;
declare foo scroll cursor for select * from generate_series(1,5) with ordinality as g(i,o);
fetch all from foo;
fetch backward all from foo;
fetch all from foo;
fetch next from foo;
fetch next from foo;
fetch prior from foo;
fetch absolute 1 from foo;
commit;

-- function with implicit LATERAL
select * from foo2, foot(foo2.fooid) z where foo2.f2 = z.f2;

-- function with implicit LATERAL and explicit ORDINALITY
select * from foo2, foot(foo2.fooid) with ordinality as z(fooid,f2,ord) where foo2.f2 = z.f2;

-- function in subselect
select * from foo2 where f2 in (select f2 from foot(foo2.fooid) z where z.fooid = foo2.fooid) ORDER BY 1,2;

-- function in subselect
select * from foo2 where f2 in (select f2 from foot(1) z where z.fooid = foo2.fooid) ORDER BY 1,2;

-- function in subselect
select * from foo2 where f2 in (select f2 from foot(foo2.fooid) z where z.fooid = 1) ORDER BY 1,2;

-- nested functions
select foot.fooid, foot.f2 from foot(sin(pi()/2)::int) ORDER BY 1,2;

CREATE TABLE foo (fooid int, foosubid int, fooname text, primary key(fooid,foosubid));
INSERT INTO foo VALUES(1,1,'Joe');
INSERT INTO foo VALUES(1,2,'Ed');
INSERT INTO foo VALUES(2,1,'Mary');

-- sql, proretset = f, prorettype = b
CREATE FUNCTION getfoo(int) RETURNS int AS 'SELECT $1;' LANGUAGE SQL;
SELECT * FROM getfoo(1) AS t1;
SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(v,o);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1);
SELECT * FROM vw_getfoo;
DROP VIEW vw_getfoo;
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) WITH ORDINALITY as t1(v,o);
SELECT * FROM vw_getfoo;

-- sql, proretset = t, prorettype = b
DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
CREATE FUNCTION getfoo(int) RETURNS setof int AS 'SELECT fooid FROM foo WHERE fooid = $1;' LANGUAGE SQL;
SELECT * FROM getfoo(1) AS t1;
SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(v,o);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1);
SELECT * FROM vw_getfoo;
DROP VIEW vw_getfoo;
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(v,o);
SELECT * FROM vw_getfoo;

-- sql, proretset = t, prorettype = b
DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
CREATE FUNCTION getfoo(int) RETURNS setof text AS 'SELECT fooname FROM foo WHERE fooid = $1;' LANGUAGE SQL;
SELECT * FROM getfoo(1) AS t1;
SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(v,o);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1);
SELECT * FROM vw_getfoo;
DROP VIEW vw_getfoo;
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(v,o);
SELECT * FROM vw_getfoo;

-- sql, proretset = f, prorettype = c
DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
CREATE FUNCTION getfoo(int) RETURNS foo AS 'SELECT * FROM foo WHERE fooid = $1;' LANGUAGE SQL;
SELECT * FROM getfoo(1) AS t1;
SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(a,b,c,o);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1);
SELECT * FROM vw_getfoo;
DROP VIEW vw_getfoo;
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(a,b,c,o);
SELECT * FROM vw_getfoo;

-- sql, proretset = t, prorettype = c
DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
CREATE FUNCTION getfoo(int) RETURNS setof foo AS 'SELECT * FROM foo WHERE fooid = $1;' LANGUAGE SQL;
SELECT * FROM getfoo(1) AS t1;
SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(a,b,c,o);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1);
SELECT * FROM vw_getfoo;
DROP VIEW vw_getfoo;
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(a,b,c,o);
SELECT * FROM vw_getfoo;

-- ordinality not supported for returns record yet
-- sql, proretset = f, prorettype = record
DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
CREATE FUNCTION getfoo(int) RETURNS RECORD AS 'SELECT * FROM foo WHERE fooid = $1;' LANGUAGE SQL;
SELECT * FROM getfoo(1) AS t1(fooid int, foosubid int, fooname text);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) AS
(fooid int, foosubid int, fooname text);
SELECT * FROM vw_getfoo;

-- sql, proretset = t, prorettype = record
DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
CREATE FUNCTION getfoo(int) RETURNS setof record AS 'SELECT * FROM foo WHERE fooid = $1;' LANGUAGE SQL;
SELECT * FROM getfoo(1) AS t1(fooid int, foosubid int, fooname text);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) AS
(fooid int, foosubid int, fooname text);
SELECT * FROM vw_getfoo;

-- plpgsql, proretset = f, prorettype = b
DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
CREATE FUNCTION getfoo(int) RETURNS int AS 'DECLARE fooint int; BEGIN SELECT fooid into fooint FROM foo WHERE fooid = $1; RETURN fooint; END;' LANGUAGE plpgsql;
SELECT * FROM getfoo(1) AS t1;
SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(v,o);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1);
SELECT * FROM vw_getfoo;
DROP VIEW vw_getfoo;
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(v,o);
SELECT * FROM vw_getfoo;

-- plpgsql, proretset = f, prorettype = c
DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
CREATE FUNCTION getfoo(int) RETURNS foo AS 'DECLARE footup foo%ROWTYPE; BEGIN SELECT * into footup FROM foo WHERE fooid = $1; RETURN footup; END;' LANGUAGE plpgsql;
SELECT * FROM getfoo(1) AS t1;
SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(a,b,c,o);
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1);
SELECT * FROM vw_getfoo;
DROP VIEW vw_getfoo;
CREATE VIEW vw_getfoo AS SELECT * FROM getfoo(1) WITH ORDINALITY AS t1(a,b,c,o);
SELECT * FROM vw_getfoo;

DROP VIEW vw_getfoo;
DROP FUNCTION getfoo(int);
DROP FUNCTION foot(int);
DROP TABLE foo2;
DROP TABLE foo;

-- Rescan tests --
CREATE TEMPORARY SEQUENCE foo_rescan_seq;
CREATE TYPE foo_rescan_t AS (i integer, s bigint);

CREATE FUNCTION foo_sql(int,int) RETURNS setof foo_rescan_t AS 'SELECT i, nextval(''foo_rescan_seq'') FROM generate_series($1,$2) i;' LANGUAGE SQL;
-- plpgsql functions use materialize mode
CREATE FUNCTION foo_mat(int,int) RETURNS setof foo_rescan_t AS 'begin for i in $1..$2 loop return next (i, nextval(''foo_rescan_seq'')); end loop; end;' LANGUAGE plpgsql;

--invokes ExecReScanFunctionScan - all these cases should materialize the function only once
-- LEFT JOIN on a condition that the planner can't prove to be true is used to ensure the function
-- is on the inner path of a nestloop join

SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r) LEFT JOIN foo_sql(11,13) ON (r+i)<100;
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r) LEFT JOIN foo_sql(11,13) WITH ORDINALITY AS f(i,s,o) ON (r+i)<100;

SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r) LEFT JOIN foo_mat(11,13) ON (r+i)<100;
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r) LEFT JOIN foo_mat(11,13) WITH ORDINALITY AS f(i,s,o) ON (r+i)<100;

SELECT * FROM (VALUES (1),(2),(3)) v(r) LEFT JOIN generate_series(11,13) f(i) ON (r+i)<100;
SELECT * FROM (VALUES (1),(2),(3)) v(r) LEFT JOIN generate_series(11,13) WITH ORDINALITY AS f(i,o) ON (r+i)<100;

SELECT * FROM (VALUES (1),(2),(3)) v(r) LEFT JOIN unnest(array[10,20,30]) f(i) ON (r+i)<100;
SELECT * FROM (VALUES (1),(2),(3)) v(r) LEFT JOIN unnest(array[10,20,30]) WITH ORDINALITY AS f(i,o) ON (r+i)<100;

--invokes ExecReScanFunctionScan with chgParam != NULL (using implied LATERAL)

SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r), foo_sql(10+r,13);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r), foo_sql(10+r,13) WITH ORDINALITY AS f(i,s,o);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r), foo_sql(11,10+r);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r), foo_sql(11,10+r) WITH ORDINALITY AS f(i,s,o);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (11,12),(13,15),(16,20)) v(r1,r2), foo_sql(r1,r2);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (11,12),(13,15),(16,20)) v(r1,r2), foo_sql(r1,r2) WITH ORDINALITY AS f(i,s,o);

SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r), foo_mat(10+r,13);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r), foo_mat(10+r,13) WITH ORDINALITY AS f(i,s,o);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r), foo_mat(11,10+r);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (1),(2),(3)) v(r), foo_mat(11,10+r) WITH ORDINALITY AS f(i,s,o);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (11,12),(13,15),(16,20)) v(r1,r2), foo_mat(r1,r2);
SELECT setval('foo_rescan_seq',1,false);
SELECT * FROM (VALUES (11,12),(13,15),(16,20)) v(r1,r2), foo_mat(r1,r2) WITH ORDINALITY AS f(i,s,o);

SELECT * FROM (VALUES (1),(2),(3)) v(r), generate_series(10+r,20-r) f(i);
SELECT * FROM (VALUES (1),(2),(3)) v(r), generate_series(10+r,20-r) WITH ORDINALITY AS f(i,o);

SELECT * FROM (VALUES (1),(2),(3)) v(r), unnest(array[r*10,r*20,r*30]) f(i);
SELECT * FROM (VALUES (1),(2),(3)) v(r), unnest(array[r*10,r*20,r*30]) WITH ORDINALITY AS f(i,o);

-- deep nesting

SELECT * FROM (VALUES (1),(2),(3)) v1(r1),
              LATERAL (SELECT r1, * FROM (VALUES (10),(20),(30)) v2(r2)
                                         LEFT JOIN generate_series(21,23) f(i) ON ((r2+i)<100) OFFSET 0) s1;
SELECT * FROM (VALUES (1),(2),(3)) v1(r1),
              LATERAL (SELECT r1, * FROM (VALUES (10),(20),(30)) v2(r2)
                                         LEFT JOIN generate_series(20+r1,23) f(i) ON ((r2+i)<100) OFFSET 0) s1;
SELECT * FROM (VALUES (1),(2),(3)) v1(r1),
              LATERAL (SELECT r1, * FROM (VALUES (10),(20),(30)) v2(r2)
                                         LEFT JOIN generate_series(r2,r2+3) f(i) ON ((r2+i)<100) OFFSET 0) s1;
SELECT * FROM (VALUES (1),(2),(3)) v1(r1),
              LATERAL (SELECT r1, * FROM (VALUES (10),(20),(30)) v2(r2)
                                         LEFT JOIN generate_series(r1,2+r2/5) f(i) ON ((r2+i)<100) OFFSET 0) s1;

DROP FUNCTION foo_sql(int,int);
DROP FUNCTION foo_mat(int,int);
DROP SEQUENCE foo_rescan_seq;

--
-- Test cases involving OUT parameters
--

CREATE FUNCTION foo(in f1 int, out f2 int)
AS 'select $1+1' LANGUAGE sql;
SELECT foo(42);
SELECT * FROM foo(42);
SELECT * FROM foo(42) AS p(x);

-- explicit spec of return type is OK
CREATE OR REPLACE FUNCTION foo(in f1 int, out f2 int) RETURNS int
AS 'select $1+1' LANGUAGE sql;
-- error, wrong result type
CREATE OR REPLACE FUNCTION foo(in f1 int, out f2 int) RETURNS float
AS 'select $1+1' LANGUAGE sql;
-- with multiple OUT params you must get a RECORD result
CREATE OR REPLACE FUNCTION foo(in f1 int, out f2 int, out f3 text) RETURNS int
AS 'select $1+1' LANGUAGE sql;
CREATE OR REPLACE FUNCTION foo(in f1 int, out f2 int, out f3 text)
RETURNS record
AS 'select $1+1' LANGUAGE sql;

CREATE OR REPLACE FUNCTION foor(in f1 int, out f2 int, out text)
AS $$select $1-1, $1::text || 'z'$$ LANGUAGE sql;
SELECT f1, foor(f1) FROM int4_tbl;
SELECT * FROM foor(42);
SELECT * FROM foor(42) AS p(a,b);

CREATE OR REPLACE FUNCTION foob(in f1 int, inout f2 int, out text)
AS $$select $2-1, $1::text || 'z'$$ LANGUAGE sql;
SELECT f1, foob(f1, f1/2) FROM int4_tbl;
SELECT * FROM foob(42, 99);
SELECT * FROM foob(42, 99) AS p(a,b);

-- Can reference function with or without OUT params for DROP, etc
DROP FUNCTION foo(int);
DROP FUNCTION foor(in f2 int, out f1 int, out text);
DROP FUNCTION foob(in f1 int, inout f2 int);

--
-- For my next trick, polymorphic OUT parameters
--

CREATE FUNCTION dup (f1 anyelement, f2 out anyelement, f3 out anyarray)
AS 'select $1, array[$1,$1]' LANGUAGE sql;
SELECT dup(22);
SELECT dup('xyz');	-- fails
SELECT dup('xyz'::text);
SELECT * FROM dup('xyz'::text);

-- fails, as we are attempting to rename first argument
CREATE OR REPLACE FUNCTION dup (inout f2 anyelement, out f3 anyarray)
AS 'select $1, array[$1,$1]' LANGUAGE sql;

DROP FUNCTION dup(anyelement);

-- equivalent behavior, though different name exposed for input arg
CREATE OR REPLACE FUNCTION dup (inout f2 anyelement, out f3 anyarray)
AS 'select $1, array[$1,$1]' LANGUAGE sql;
SELECT dup(22);

DROP FUNCTION dup(anyelement);

-- fails, no way to deduce outputs
CREATE FUNCTION bad (f1 int, out f2 anyelement, out f3 anyarray)
AS 'select $1, array[$1,$1]' LANGUAGE sql;

--
-- table functions
--

CREATE OR REPLACE FUNCTION foo()
RETURNS TABLE(a int)
AS $$ SELECT a FROM generate_series(1,5) a(a) $$ LANGUAGE sql;
SELECT * FROM foo();
DROP FUNCTION foo();

CREATE OR REPLACE FUNCTION foo(int)
RETURNS TABLE(a int, b int)
AS $$ SELECT a, b
         FROM generate_series(1,$1) a(a),
              generate_series(1,$1) b(b) $$ LANGUAGE sql;
SELECT * FROM foo(3);
DROP FUNCTION foo(int);

--
-- some tests on SQL functions with RETURNING
--

create temp table tt(f1 serial, data text);

create function insert_tt(text) returns int as
$$ insert into tt(data) values($1) returning f1 $$
language sql;

select insert_tt('foo');
select insert_tt('bar');
select * from tt;

-- insert will execute to completion even if function needs just 1 row
create or replace function insert_tt(text) returns int as
$$ insert into tt(data) values($1),($1||$1) returning f1 $$
language sql;

select insert_tt('fool');
select * from tt;

-- setof does what's expected
create or replace function insert_tt2(text,text) returns setof int as
$$ insert into tt(data) values($1),($2) returning f1 $$
language sql;

select insert_tt2('foolish','barrish');
select * from insert_tt2('baz','quux');
select * from tt;

-- limit doesn't prevent execution to completion
select insert_tt2('foolish','barrish') limit 1;
select * from tt;

-- triggers will fire, too
create function noticetrigger() returns trigger as $$
begin
  raise notice 'noticetrigger % %', new.f1, new.data;
  return null;
end $$ language plpgsql;
create trigger tnoticetrigger after insert on tt for each row
execute procedure noticetrigger();

select insert_tt2('foolme','barme') limit 1;
select * from tt;

-- and rules work
create temp table tt_log(f1 int, data text);

create rule insert_tt_rule as on insert to tt do also
  insert into tt_log values(new.*);

select insert_tt2('foollog','barlog') limit 1;
select * from tt;
-- note that nextval() gets executed a second time in the rule expansion,
-- which is expected.
select * from tt_log;

-- test case for a whole-row-variable bug
create function foo1(n integer, out a text, out b text)
  returns setof record
  language sql
  as $$ select 'foo ' || i, 'bar ' || i from generate_series(1,$1) i $$;

set work_mem='64kB';
select t.a, t, t.a from foo1(10000) t limit 1;
reset work_mem;
select t.a, t, t.a from foo1(10000) t limit 1;

drop function foo1(n integer);

-- test use of SQL functions returning record
-- this is supported in some cases where the query doesn't specify
-- the actual record type ...

create function array_to_set(anyarray) returns setof record as $$
  select i AS "index", $1[i] AS "value" from generate_subscripts($1, 1) i
$$ language sql strict immutable;

select array_to_set(array['one', 'two']);
select * from array_to_set(array['one', 'two']) as t(f1 int,f2 text);
select * from array_to_set(array['one', 'two']); -- fail

create temp table foo(f1 int8, f2 int8);

create function testfoo() returns record as $$
  insert into foo values (1,2) returning *;
$$ language sql;

select testfoo();
select * from testfoo() as t(f1 int8,f2 int8);
select * from testfoo(); -- fail

drop function testfoo();

create function testfoo() returns setof record as $$
  insert into foo values (1,2), (3,4) returning *;
$$ language sql;

select testfoo();
select * from testfoo() as t(f1 int8,f2 int8);
select * from testfoo(); -- fail

drop function testfoo();

--
-- Check some cases involving dropped columns in a rowtype result
--

create temp table users (userid text, email text, todrop bool, enabled bool);
insert into users values ('id','email',true,true);
insert into users values ('id2','email2',true,true);
alter table users drop column todrop;

create or replace function get_first_user() returns users as
$$ SELECT * FROM users ORDER BY userid LIMIT 1; $$
language sql stable;

SELECT get_first_user();
SELECT * FROM get_first_user();

create or replace function get_users() returns setof users as
$$ SELECT * FROM users ORDER BY userid; $$
language sql stable;

SELECT get_users();
SELECT * FROM get_users();
SELECT * FROM get_users() WITH ORDINALITY;   -- make sure ordinality copes

drop function get_first_user();
drop function get_users();
drop table users;

-- this won't get inlined because of type coercion, but it shouldn't fail

create or replace function foobar() returns setof text as
$$ select 'foo'::varchar union all select 'bar'::varchar ; $$
language sql stable;

select foobar();
select * from foobar();

drop function foobar();

-- check handling of a SQL function with multiple OUT params (bug #5777)

create or replace function foobar(out integer, out numeric) as
$$ select (1, 2.1) $$ language sql;

select * from foobar();

create or replace function foobar(out integer, out numeric) as
$$ select (1, 2) $$ language sql;

select * from foobar();  -- fail

create or replace function foobar(out integer, out numeric) as
$$ select (1, 2.1, 3) $$ language sql;

select * from foobar();  -- fail

drop function foobar();
