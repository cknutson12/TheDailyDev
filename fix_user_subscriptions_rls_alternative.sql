-- Alternative: Fix RLS Policy for user_subscriptions table
-- This version tries both UUID and TEXT comparisons

-- Step 1: Ensure RLS is enabled
ALTER TABLE user_subscriptions
  ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing insert policy if it exists (to recreate it)
DROP POLICY IF EXISTS "Users can insert their own subscription" ON user_subscriptions;

-- Step 3: Create insert policy
-- Try this if user_id is UUID type:
-- CREATE POLICY "Users can insert their own subscription"
--   ON user_subscriptions
--   FOR INSERT
--   WITH CHECK (auth.uid() = user_id);

-- OR try this if user_id is TEXT type:
CREATE POLICY "Users can insert their own subscription"
  ON user_subscriptions
  FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

-- Step 4: Ensure update policy exists
DROP POLICY IF EXISTS "Users can update their own subscription" ON user_subscriptions;

-- If user_id is UUID:
-- CREATE POLICY "Users can update their own subscription"
--   ON user_subscriptions
--   FOR UPDATE
--   USING (auth.uid() = user_id)
--   WITH CHECK (auth.uid() = user_id);

-- If user_id is TEXT:
CREATE POLICY "Users can update their own subscription"
  ON user_subscriptions
  FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

-- Step 5: Ensure select policy exists
DROP POLICY IF EXISTS "Users can view their own subscription" ON user_subscriptions;

-- If user_id is UUID:
-- CREATE POLICY "Users can view their own subscription"
--   ON user_subscriptions
--   FOR SELECT
--   USING (auth.uid() = user_id);

-- If user_id is TEXT:
CREATE POLICY "Users can view their own subscription"
  ON user_subscriptions
  FOR SELECT
  USING (auth.uid()::text = user_id);

