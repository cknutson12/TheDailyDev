-- Migration: Add RevenueCat columns to user_subscriptions table
-- This migration adds RevenueCat-specific columns to support the RevenueCat integration
-- Note: subscription_plans table was removed as plan data now comes directly from RevenueCat

-- Add RevenueCat columns to user_subscriptions table
ALTER TABLE user_subscriptions
ADD COLUMN IF NOT EXISTS revenuecat_user_id TEXT,
ADD COLUMN IF NOT EXISTS revenuecat_subscription_id TEXT,
ADD COLUMN IF NOT EXISTS entitlement_status TEXT,
ADD COLUMN IF NOT EXISTS original_transaction_id TEXT;

-- Add comments for documentation
COMMENT ON COLUMN user_subscriptions.revenuecat_user_id IS 'RevenueCat user ID (App User ID) - links to Supabase user_id after logIn()';
COMMENT ON COLUMN user_subscriptions.revenuecat_subscription_id IS 'RevenueCat subscription/transaction ID from webhook events';
COMMENT ON COLUMN user_subscriptions.entitlement_status IS 'RevenueCat entitlement status (active, expired, billing_issue, paused, etc.)';
COMMENT ON COLUMN user_subscriptions.original_transaction_id IS 'Original transaction ID for restore purchases and subscription management';

