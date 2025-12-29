-- Alternative: Database Trigger Approach
-- This automatically creates user_subscriptions record when a user signs up
-- Users never directly insert into user_subscriptions table

-- Step 1: Create function that automatically creates user_subscriptions record
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Automatically create user_subscriptions record when new user is created
  INSERT INTO public.user_subscriptions (user_id, status)
  VALUES (NEW.id::text, 'inactive')
  ON CONFLICT (user_id) DO NOTHING; -- Prevent duplicates
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create trigger that fires when new user is created in auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 3: Update RLS to allow users to UPDATE their own records (but not INSERT)
ALTER TABLE user_subscriptions
  ENABLE ROW LEVEL SECURITY;

-- Drop INSERT policy (users can't insert directly anymore)
DROP POLICY IF EXISTS "Users can insert their own subscription" ON user_subscriptions;

-- Keep UPDATE policy (users can update their name)
DROP POLICY IF EXISTS "Users can update their own subscription" ON user_subscriptions;

CREATE POLICY "Users can update their own subscription"
  ON user_subscriptions
  FOR UPDATE
  USING (auth.uid()::text = user_id)
  WITH CHECK (auth.uid()::text = user_id);

-- Keep SELECT policy
DROP POLICY IF EXISTS "Users can view their own subscription" ON user_subscriptions;

CREATE POLICY "Users can view their own subscription"
  ON user_subscriptions
  FOR SELECT
  USING (auth.uid()::text = user_id);

-- Note: With this approach:
-- 1. Record is created automatically when user signs up (via trigger)
-- 2. App code should UPDATE the record with first_name/last_name, not INSERT
-- 3. Users cannot insert records directly (more secure)

