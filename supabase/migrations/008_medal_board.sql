-- ============================================================================
-- Medal board.
--
-- A fourth global board beside Endless, Hardcore and the dailies: the miners
-- with the most daily medals, ranked like an Olympic table -- most golds
-- first, then silvers, then bronzes. A tie on all three goes to whoever
-- completed that tally first (the earlier date of their latest medal).
--
-- This migration:
--   * adds medals_top(n), the medal board (readable by anyone, like the
--     other boards);
--   * adds medals_rank to my_ranks(), so a player off the bottom of the list
--     still sees where they stand (null until they have a medal).
--
-- Safe to apply before or after the build that shows the tab: older builds
-- never call medals_top and read my_ranks() columns by name.
-- ============================================================================


-- ------------------------------------------------------------ the board ----

-- Each medalled player's tally, with the date that settles a full tie.
create function public.medal_table() returns table (
  user_id uuid, gold int, silver int, bronze int, last_medal date)
language sql stable security definer set search_path = '' as $$
  select dm.user_id,
         count(*) filter (where dm.medal = 'gold')::int,
         count(*) filter (where dm.medal = 'silver')::int,
         count(*) filter (where dm.medal = 'bronze')::int,
         max(dm.daily_date)
    from public.daily_medals dm
   group by dm.user_id
$$;

revoke execute on function public.medal_table() from public, anon, authenticated;

-- Top `n` of the medal board. `me` marks the caller's row.
create function public.medals_top(n int default 50) returns table (
  rank bigint, name text, tag text, gold int, silver int, bronze int, me boolean)
language sql stable security definer set search_path = '' as $$
  select row_number() over (order by t.gold desc, t.silver desc, t.bronze desc, t.last_medal, t.user_id) as rank,
         p.display_name, public.anon_tag(t.user_id), t.gold, t.silver, t.bronze,
         t.user_id = auth.uid()
    from public.medal_table() t
    join public.profiles p on p.id = t.user_id
   order by t.gold desc, t.silver desc, t.bronze desc, t.last_medal, t.user_id
   limit least(greatest(n, 1), 200)
$$;


-- ------------------------------------------------------------ my_ranks ----

-- my_ranks() gains a column, so it is dropped and made again (a function's
-- result type cannot be changed in place). Older builds read only the
-- columns they know, so the new one goes on the end.
drop function public.my_ranks();
create function public.my_ranks() returns table (
  endless_rank bigint, endless_best int, daily_rank bigint, daily_best int,
  hardcore_rank bigint, hardcore_best int, medals_rank bigint)
language sql stable security definer set search_path = '' as $$
  with e as (select * from public.endless_best()),
       d as (select * from public.daily_best(public.utc_today(), public.daily_cutoff(public.utc_today()))),
       h as (select * from public.hardcore_best()),
       m as (select * from public.medal_table())
  select (select 1 + (select count(*) from e x
                       where x.score > me.score
                          or (x.score = me.score and x.created_at < me.created_at))
            from e me where me.user_id = auth.uid()),
         (select me.score from e me where me.user_id = auth.uid()),
         (select 1 + (select count(*) from d x
                       where x.score > me.score
                          or (x.score = me.score and x.created_at < me.created_at))
            from d me where me.user_id = auth.uid()),
         (select me.score from d me where me.user_id = auth.uid()),
         (select 1 + (select count(*) from h x
                       where x.score > me.score
                          or (x.score = me.score and x.created_at < me.created_at))
            from h me where me.user_id = auth.uid()),
         (select me.score from h me where me.user_id = auth.uid()),
         (select 1 + (select count(*) from m x
                       where (x.gold, x.silver, x.bronze) > (me.gold, me.silver, me.bronze)
                          or ((x.gold, x.silver, x.bronze) = (me.gold, me.silver, me.bronze)
                              and (x.last_medal, x.user_id) < (me.last_medal, me.user_id)))
            from m me where me.user_id = auth.uid())
$$;


-- ------------------------------------------------------------- grants ----

revoke execute on function public.medals_top(int), public.my_ranks()
  from public, anon, authenticated;
grant execute on function public.medals_top(int) to anon, authenticated;
grant execute on function public.my_ranks() to authenticated;
