# PostHog Dashboard Setup Guide

## Why Dashboards Are Empty

PostHog dashboards don't automatically populate with data. You need to:
1. **Create Insights** (charts/graphs) from your events
2. **Add Insights to Dashboards** to visualize them

The "Activity" section shows raw events, but dashboards need to be configured with specific insights.

## Step-by-Step Dashboard Setup

### Step 1: Create Your First Insight

1. **Go to Insights**
   - In PostHog, click **"Insights"** in the left sidebar
   - Click **"+ New Insight"** button (top right)

2. **Choose Insight Type**
   - Select **"Trends"** (most common for event tracking)
   - This shows how events change over time

3. **Configure the Insight**
   - **Event**: Select `Application Opened` (or any event you want to track)
   - **Chart Type**: Choose "Line chart" or "Bar chart"
   - **Date Range**: Select a time period (e.g., "Last 7 days")
   - Click **"Save"** or **"Save as"**

4. **Name Your Insight**
   - Give it a descriptive name like "App Opens Over Time"
   - Click **"Save"**

### Step 2: Create More Insights

Create insights for key metrics:

#### User Engagement
- **Daily Active Users**: 
  - Event: `Application Opened`
  - Aggregation: Unique users
  - Name: "Daily Active Users"

- **Question Views**:
  - Event: `question_viewed`
  - Name: "Questions Viewed"

- **Questions Answered**:
  - Event: `question_answered`
  - Name: "Questions Answered"

#### Conversion Funnel
- **Sign-Up Funnel**:
  - Type: **"Funnel"** (instead of Trends)
  - Steps:
    1. `Application Opened`
    2. `sign_up_started`
    3. `sign_up_completed`
    4. `first_question_answered`
  - Name: "Sign-Up to First Question Funnel"

#### Subscription Metrics
- **Paywall Views**:
  - Event: `paywall_viewed`
  - Name: "Paywall Views"

- **Subscription Purchases**:
  - Event: `subscription_purchased`
  - Name: "Subscription Purchases"

- **Conversion Rate**:
  - Type: **"Funnel"**
  - Steps:
    1. `paywall_viewed`
    2. `subscription_purchased`
  - Name: "Paywall to Purchase Conversion"

### Step 3: Create a Dashboard

1. **Go to Dashboards**
   - Click **"Dashboards"** in the left sidebar
   - Click **"+ New Dashboard"**

2. **Name Your Dashboard**
   - Enter a name like "The Daily Dev - Main Dashboard"
   - Click **"Create"**

3. **Add Insights to Dashboard**
   - Click **"Add insight"** or **"Add graph"**
   - Select the insights you created
   - Or create new insights directly from the dashboard

4. **Arrange Your Dashboard**
   - Drag and drop insights to arrange them
   - Resize insights by dragging corners
   - Click **"Save"** when done

### Step 4: Recommended Dashboard Layout

Here's a suggested layout for your main dashboard:

#### Row 1: Key Metrics (4 columns)
1. **Daily Active Users** (Trends - Unique users, `Application Opened`)
2. **Questions Answered Today** (Trends - Count, `question_answered`)
3. **New Sign-Ups Today** (Trends - Count, `sign_up_completed`)
4. **Subscription Purchases** (Trends - Count, `subscription_purchased`)

#### Row 2: Engagement (2 columns)
1. **Questions Viewed Over Time** (Trends - Line chart, `question_viewed`)
2. **Questions Answered Over Time** (Trends - Line chart, `question_answered`)

#### Row 3: Conversion Funnel (Full width)
1. **Sign-Up to First Question Funnel** (Funnel - `Application Opened` → `sign_up_completed` → `first_question_answered`)

#### Row 4: Subscription Metrics (2 columns)
1. **Paywall to Purchase Conversion** (Funnel - `paywall_viewed` → `subscription_purchased`)
2. **Subscription Status Distribution** (Trends - Breakdown by `subscription_status` user property)

### Step 5: Quick Setup Templates

PostHog offers templates to get started quickly:

1. **Go to Dashboards**
2. Click **"+ New Dashboard"**
3. Select **"From template"** (if available)
4. Choose a template like:
   - "Product Analytics"
   - "Growth Metrics"
   - "User Engagement"

### Step 6: Set Dashboard as Default

1. **Open your dashboard**
2. Click the **"..."** menu (top right)
3. Select **"Set as default dashboard"**
4. This dashboard will now appear when you open PostHog

## Common Insight Types

### Trends
- **Best for**: Tracking event counts over time
- **Examples**: Daily active users, questions answered per day
- **Configuration**: Event → Chart type → Date range

### Funnels
- **Best for**: Conversion tracking
- **Examples**: Sign-up funnel, purchase funnel
- **Configuration**: Multiple events in sequence → Conversion rate

### Retention
- **Best for**: User retention analysis
- **Examples**: Day 1, Day 7, Day 30 retention
- **Configuration**: Initial event → Return event → Time period

### Paths
- **Best for**: User journey analysis
- **Examples**: How users navigate through the app
- **Configuration**: Starting point → Path analysis

## Quick Reference: Events to Track

Here are the events you're currently tracking that you can use in insights:

### App Lifecycle
- `Application Opened` - App launches
- `app_foreground` - App comes to foreground
- `app_background` - App goes to background

### Authentication
- `sign_up_started` - User begins sign-up
- `sign_up_completed` - User completes sign-up
- `user_signed_in` - User signs in
- `user_signed_out` - User signs out

### Onboarding
- `onboarding_viewed` - Onboarding screen appears
- `onboarding_completed` - User completes onboarding
- `onboarding_tour_started` - Tour begins
- `onboarding_tour_completed` - Tour completes

### Questions
- `question_viewed` - Question is viewed
- `question_answered` - Question is answered
- `question_correct` - Answer is correct
- `question_incorrect` - Answer is incorrect
- `first_question_answered` - First question answered

### Subscriptions
- `paywall_viewed` - Paywall appears
- `subscription_purchase_started` - Purchase begins
- `subscription_purchased` - Purchase completes
- `subscription_purchase_failed` - Purchase fails
- `subscription_restored` - Purchase restored

### Screens
- `screen_view` - Screen is viewed (with `screen_name` property)

## Tips for Better Dashboards

1. **Start Simple**: Create 3-5 key insights first, then expand
2. **Use Descriptive Names**: Name insights clearly (e.g., "Daily Active Users" not "DAU")
3. **Set Appropriate Time Ranges**: Use "Last 7 days" for trends, "Last 30 days" for retention
4. **Group Related Metrics**: Put similar metrics together (e.g., all subscription metrics in one section)
5. **Use Filters**: Filter insights by user properties (e.g., subscription status, sign-up method)
6. **Set Up Alerts**: Create alerts for important metrics (e.g., "Alert if sign-ups drop below X")

## Troubleshooting

### Insight Shows "No Data"
- **Check Date Range**: Make sure the date range includes when events occurred
- **Verify Event Name**: Event names are case-sensitive - check exact spelling
- **Check Filters**: Remove any filters that might be excluding data
- **Wait a Few Minutes**: New events may take a minute to appear in insights

### Dashboard Not Updating
- **Refresh the Page**: Dashboards don't auto-refresh
- **Check Data Freshness**: Look for "Last updated" timestamp
- **Verify Events Are Being Sent**: Check "Activity" to confirm events are arriving

### Can't Find an Event
- **Check Activity Tab**: Verify the event exists in raw events
- **Check Event Name**: Use exact event name (case-sensitive)
- **Check Time Range**: Events might be outside the selected date range

## Next Steps

1. **Create Your First Insight**: Start with "Daily Active Users"
2. **Create a Dashboard**: Add 3-5 key insights
3. **Set as Default**: Make it your default dashboard
4. **Add More Over Time**: Expand as you identify important metrics

For more help:
- [PostHog Insights Documentation](https://posthog.com/docs/user-guides/insights)
- [PostHog Dashboards Documentation](https://posthog.com/docs/user-guides/dashboards)
- [PostHog Funnels Guide](https://posthog.com/docs/user-guides/funnels)