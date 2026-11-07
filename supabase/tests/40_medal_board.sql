-- Medal board (008). Run after 30_hardcore.sql: inserts medals by hand (as
-- the owner, the way award_daily_medals would) and checks the ordering.
\set ON_ERROR_STOP 0
\pset footer off
delete from public.daily_medals;
insert into auth.users (id) values
  ('33333333-3333-3333-3333-333333333333'), ('44444444-4444-4444-4444-444444444444')
  on conflict do nothing;
insert into public.profiles (id) values
  ('33333333-3333-3333-3333-333333333333'), ('44444444-4444-4444-4444-444444444444')
  on conflict do nothing;
-- u1: 1 gold 0 silver 5 bronze. u2: 1 gold 2 silver. u3: 0 gold 9 silver.
-- u4: 1 gold 2 silver, same as u2 but completed earlier -> above u2.
insert into public.daily_medals (daily_date, medal, user_id, score) values
  (current_date - 40, 'gold',   '11111111-1111-1111-1111-111111111111', 1),
  (current_date - 41, 'bronze', '11111111-1111-1111-1111-111111111111', 1),
  (current_date - 42, 'bronze', '11111111-1111-1111-1111-111111111111', 1),
  (current_date - 43, 'bronze', '11111111-1111-1111-1111-111111111111', 1),
  (current_date - 44, 'bronze', '11111111-1111-1111-1111-111111111111', 1),
  (current_date - 45, 'bronze', '11111111-1111-1111-1111-111111111111', 1),
  (current_date - 10, 'gold',   '22222222-2222-2222-2222-222222222222', 1),
  (current_date - 11, 'silver', '22222222-2222-2222-2222-222222222222', 1),
  (current_date - 12, 'silver', '22222222-2222-2222-2222-222222222222', 1),
  (current_date - 50, 'gold',   '44444444-4444-4444-4444-444444444444', 1),
  (current_date - 51, 'silver', '44444444-4444-4444-4444-444444444444', 1),
  (current_date - 52, 'silver', '44444444-4444-4444-4444-444444444444', 1);
insert into public.daily_medals (daily_date, medal, user_id, score)
  select current_date - 60 - g, 'silver', '33333333-3333-3333-3333-333333333333', 1 from generate_series(1, 9) g;

set role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
\echo == expect: u4 (1/2/0, earlier), u2 (1/2/0, me), u1 (1/0/5), u3 (0/9/0)
select rank, tag, gold, silver, bronze, me from public.medals_top();
\echo == n = 2 cuts the list; u2 stands 2nd in my_ranks
select rank, gold, silver, bronze from public.medals_top(2);
select medals_rank, endless_rank, hardcore_rank from public.my_ranks();
\echo == a player with no medal has no medal rank
select set_config('request.jwt.claim.sub','55555555-5555-5555-5555-555555555555',false);
select medals_rank from public.my_ranks();
reset role;
\echo == anon can read the medal board, not the helper
set role anon;
select count(*) from public.medals_top();
select * from public.medal_table();
reset role;
