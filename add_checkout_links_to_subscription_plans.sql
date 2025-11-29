-- Add checkout link fields to subscription_plans table
-- These will store pre-created Stripe checkout links for easy updating via Supabase dashboard

ALTER TABLE subscription_plans
ADD COLUMN IF NOT EXISTS checkout_link_trial TEXT,
ADD COLUMN IF NOT EXISTS checkout_link_no_trial TEXT;

-- Add comments to document the fields
COMMENT ON COLUMN subscription_plans.checkout_link_trial IS 'Pre-created Stripe checkout link for subscription WITH trial period. Update via Supabase dashboard Table Editor.';
COMMENT ON COLUMN subscription_plans.checkout_link_no_trial IS 'Pre-created Stripe checkout link for subscription WITHOUT trial (immediate billing). Update via Supabase dashboard Table Editor.';

