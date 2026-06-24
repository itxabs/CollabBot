-- This file previously contained a dangerous trigger that truncated the table on every swipe.
-- It has been removed. 
-- To reset swipes for a specific user, use the 'restore' action in the app or call the /swap/swipe API with action="restore".

-- If you still want a way to truncate the table MANUALLY, you can use:
-- TRUNCATE TABLE public.swipe_actions;