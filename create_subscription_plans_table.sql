-- Create subscription_plans table for dynamic pricing
-- This allows updating prices without releasing a new app version

CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE, -- e.g., 'monthly', 'annual'
    stripe_price_id TEXT NOT NULL UNIQUE,
    price_amount DECIMAL(10, 2) NOT NULL, -- e.g., 4.99
    currency TEXT NOT NULL DEFAULT 'usd',
    billing_period TEXT NOT NULL, -- 'month' or 'year'
    is_active BOOLEAN NOT NULL DEFAULT true,
    trial_days INTEGER NOT NULL DEFAULT 7,
    display_name TEXT, -- e.g., "Monthly Plan"
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert the monthly plan
INSERT INTO subscription_plans (
    name,
    stripe_price_id,
    price_amount,
    currency,
    billing_period,
    is_active,
    trial_days,
    display_name,
    description
) VALUES (
    'monthly',
    'price_1SREPsK9eNlBD1eEdAJAAhlc', -- Update this with your new Stripe price ID for $4.99
    4.99,
    'usd',
    'month',
    true,
    7,
    'Monthly Plan',
    'Unlimited access to daily questions and progress tracking'
) ON CONFLICT (name) DO UPDATE
SET 
    stripe_price_id = EXCLUDED.stripe_price_id,
    price_amount = EXCLUDED.price_amount,
    updated_at = NOW();

-- Insert the annual plan
INSERT INTO subscription_plans (
    name,
    stripe_price_id,
    price_amount,
    currency,
    billing_period,
    is_active,
    trial_days,
    display_name,
    description
) VALUES (
    'annual',
    'YOUR_ANNUAL_PRICE_ID_HERE', -- Update this with your Stripe annual price ID for $40.00
    40.00,
    'usd',
    'year',
    true,
    7,
    'Annual Plan',
    'Unlimited access to daily questions and progress tracking - Save 33%!'
) ON CONFLICT (name) DO UPDATE
SET 
    stripe_price_id = EXCLUDED.stripe_price_id,
    price_amount = EXCLUDED.price_amount,
    updated_at = NOW();

-- Enable RLS (Row Level Security)
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read active plans (needed for pricing display)
CREATE POLICY "Anyone can view active subscription plans"
    ON subscription_plans
    FOR SELECT
    USING (is_active = true);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active ON subscription_plans(is_active, name);

-- Add comment
COMMENT ON TABLE subscription_plans IS 'Stores subscription plan pricing. Update prices here to change them without app release.';

