-- Add unique constraint on user_id to ensure only one subscription record per user
-- This prevents duplicate entries when opening Stripe portal or during signup

-- First, check if there are any duplicate user_ids and handle them
-- (You may want to review and merge duplicates manually before running this)

-- Add unique constraint
ALTER TABLE user_subscriptions
ADD CONSTRAINT user_subscriptions_user_id_key UNIQUE (user_id);

-- If the above fails due to existing duplicates, you can:
-- 1. First identify duplicates:
-- SELECT user_id, COUNT(*) 
-- FROM user_subscriptions 
-- GROUP BY user_id 
-- HAVING COUNT(*) > 1;

-- 2. Keep the most recent record for each user and delete others:
-- DELETE FROM user_subscriptions
-- WHERE id NOT IN (
--   SELECT DISTINCT ON (user_id) id
--   FROM user_subscriptions
--   ORDER BY user_id, created_at DESC
-- );

-- 3. Then add the constraint:
-- ALTER TABLE user_subscriptions
-- ADD CONSTRAINT user_subscriptions_user_id_key UNIQUE (user_id);

COMMENT ON CONSTRAINT user_subscriptions_user_id_key ON user_subscriptions IS 'Ensures only one subscription record exists per user';

