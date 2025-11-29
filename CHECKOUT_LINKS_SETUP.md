# Checkout Links Configuration

The app uses pre-created Stripe checkout links stored directly in the `subscription_plans` table. This keeps all plan information together and makes it easy to update links from the Supabase dashboard.

## Setup Steps

1. **Run the SQL migration** to add checkout link columns:
   ```sql
   -- Run: add_checkout_links_to_subscription_plans.sql
   ```

2. **Add your Stripe checkout links** to each plan in the `subscription_plans` table:
   - Go to **Table Editor** → `subscription_plans`
   - For each plan (monthly, annual), update:
     - `checkout_link_trial` - Link for subscription WITH trial
     - `checkout_link_no_trial` - Link for subscription WITHOUT trial

## How to Update Links

### Via Supabase Dashboard:
1. Go to your Supabase project dashboard
2. Navigate to **Table Editor** → `subscription_plans`
3. Click on the plan row you want to update (e.g., "monthly" or "annual")
4. Edit the `checkout_link_trial` or `checkout_link_no_trial` field with your Stripe checkout link URL
5. Click **Save**

### Via SQL Editor:
```sql
-- Update monthly plan links
UPDATE subscription_plans 
SET 
    checkout_link_trial = 'https://checkout.stripe.com/your-monthly-trial-link',
    checkout_link_no_trial = 'https://checkout.stripe.com/your-monthly-no-trial-link'
WHERE name = 'monthly';

-- Update annual plan links
UPDATE subscription_plans 
SET 
    checkout_link_trial = 'https://checkout.stripe.com/your-annual-trial-link',
    checkout_link_no_trial = 'https://checkout.stripe.com/your-annual-no-trial-link'
WHERE name = 'annual';
```

## How It Works

- Each plan in `subscription_plans` has two checkout link fields:
  - `checkout_link_trial` - Used when user wants a trial period
  - `checkout_link_no_trial` - Used when user skips trial (immediate billing)
- The app automatically selects the correct link based on:
  - **Plan selection**: Monthly or Annual (from `subscription_plans` table)
  - **Trial preference**: With trial or without trial (from user selection)
- Links are cached for 1 hour (same cache as subscription plans)

## Link Selection Logic

The app automatically selects the correct link:
- If `skipTrial = false` → uses `checkout_link_trial`
- If `skipTrial = true` → uses `checkout_link_no_trial`

## Coupon Code Support

If a user enters a coupon code, it's automatically appended to the checkout URL as a query parameter:
```
https://checkout.stripe.com/your-link?promo_code=FRIENDS99
```

## Notes

- Links are fetched with subscription plans (cached for 1 hour)
- You can update links anytime in Supabase - changes will be picked up within 1 hour
- To force immediate refresh, restart the app
- Make sure your Stripe checkout links are set to the correct success/cancel URLs:
  - Success: `thedailydev://subscription-success?session_id={CHECKOUT_SESSION_ID}`
  - Cancel: `thedailydev://subscription-cancel`
