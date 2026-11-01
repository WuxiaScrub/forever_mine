-- ============================================================================
-- Daily generator version 3.
--
-- World generation changed: the daily mine is no longer an endless mine on a
-- fixed seed. Each day is built to one of three plans rolled from the day's
-- seed (CFG.daily: fault lines, the broad seam, switchbacks). The seed itself
-- includes the generator version, so version-2 and version-3 builds dig
-- different daily mines, and the board must only compare runs from the same
-- one. This moves the daily board to version 3.
--
-- Apply it once the build with CFG.online.genVersion = 3 is live, ideally
-- just after 00:00 UTC: the board drops that day's version-2 runs, and
-- version-2 builds have their daily runs refused (stale_daily) from now on.
-- ============================================================================

update public.app_config set value = '3' where key = 'gen_version';
