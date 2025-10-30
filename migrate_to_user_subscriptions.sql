-- Migration: Move name data from user_profiles to user_subscriptions
-- This adds first_name and last_name columns to user_subscriptions table

-- Step 1: Add the new columns to user_subscriptions table
ALTER TABLE user_subscriptions
ADD COLUMN IF NOT EXISTS first_name TEXT,
ADD COLUMN IF NOT EXISTS last_name TEXT;

-- Step 2: Migrate existing data from user_profiles (optional - if you have existing data)
-- This assumes you want to move data from user_profiles.name to user_subscriptions
-- Uncomment and adjust if you have existing users:

/*
UPDATE user_subscriptions us
SET first_name = split_part(up.name, ' ', 1),
    last_name = split_part(up.name, ' ', 2)
FROM user_profiles up
WHERE us.user_id::text = up.id;
*/

-- Step 3: Update RLS policies to allow users to update their own name
ALTER TABLE user_subscriptions
  ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (adjust if needed)
DROP POLICY IF EXISTS "Users can update their own subscription" ON user_subscriptions;

-- Recreate policy that allows name updates
CREATE POLICY "Users can update their own subscription"
  ON user_subscriptions
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Step 4: Update insert policy to allow name insertion
DROP POLICY IF EXISTS "Users can insert their own subscription" ON user_subscriptions;

CREATE POLICY "Users can insert their own subscription"
  ON user_subscriptions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Note: After running this, you can delete the user_profiles table if no longer needed:
-- DROP TABLE IF EXISTS user_profiles CASCADE;

