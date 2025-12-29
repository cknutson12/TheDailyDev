-- Fix RLS Policy for user_subscriptions table
-- This allows users to insert their own subscription records with first_name and last_name

-- Step 1: Ensure RLS is enabled
ALTER TABLE user_subscriptions
  ENABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing insert policy if it exists (to recreate it)
DROP POLICY IF EXISTS "Users can insert their own subscription" ON user_subscriptions;

-- Step 3: Create insert policy that allows users to insert their own records
-- This policy checks that auth.uid() matches the user_id being inserted
-- Note: user_id is UUID type, so we cast both to TEXT for comparison
CREATE POLICY "Users can insert their own subscription"
  ON user_subscriptions
  FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

-- Step 4: Ensure update policy exists (for name updates)
DROP POLICY IF EXISTS "Users can update their own subscription" ON user_subscriptions;

CREATE POLICY "Users can update their own subscription"
  ON user_subscriptions
  FOR UPDATE
  USING (auth.uid()::text = user_id::text)
  WITH CHECK (auth.uid()::text = user_id::text);

-- Step 5: Ensure select policy exists (for reading own records)
DROP POLICY IF EXISTS "Users can view their own subscription" ON user_subscriptions;

CREATE POLICY "Users can view their own subscription"
  ON user_subscriptions
  FOR SELECT
  USING (auth.uid()::text = user_id::text);

-- Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'user_subscriptions'
ORDER BY policyname;

