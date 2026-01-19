-- Database Performance Indexes for The Daily Dev
-- Run these in Supabase SQL Editor to optimize query performance

-- ============================================================================
-- USER_PROGRESS TABLE INDEXES
-- ============================================================================

-- 1. Lookup progress by user and completion time (for streak calculation, history)
-- Used by: fetchUserProgressHistory(), calculateCurrentStreak()
CREATE INDEX IF NOT EXISTS idx_user_progress_user_completed 
ON user_progress(user_id, completed_at DESC);

-- 2. Check if user answered a specific question (hasAnsweredToday check)
-- Used by: hasAnsweredToday() when checking if user answered today's question
CREATE INDEX IF NOT EXISTS idx_user_progress_user_question 
ON user_progress(user_id, question_id);

-- 3. Count user's total answers (hasAnsweredAnyQuestion)
-- Used by: hasAnsweredAnyQuestion() for first question check
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id 
ON user_progress(user_id);

-- ============================================================================
-- USER_SUBSCRIPTIONS TABLE INDEXES
-- ============================================================================

-- 4. Lookup subscription by user (primary lookup pattern)
-- Used by: fetchSubscriptionStatus(), getUserDisplayName()
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user 
ON user_subscriptions(user_id);

-- 5. Lookup by Stripe customer ID (webhook processing)
-- Note: Stripe indexes removed - we now use RevenueCat
-- The stripe_customer_id column has been removed from user_subscriptions table

-- ============================================================================
-- DAILY_CHALLENGES TABLE INDEXES
-- ============================================================================

-- 6. Lookup today's challenge by date
-- Used by: fetchTodaysQuestion(), hasAnsweredToday()
CREATE INDEX IF NOT EXISTS idx_daily_challenges_date 
ON daily_challenges(challenge_date DESC);

-- ============================================================================
-- QUESTIONS TABLE INDEXES (if needed)
-- ============================================================================

-- 7. Lookup questions by category (for category performance)
-- Used by: calculateCategoryPerformance() when grouping by category
-- Only add if you notice slow category queries
-- CREATE INDEX IF NOT EXISTS idx_questions_category 
-- ON questions(category);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- After running, verify indexes were created:
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('user_progress', 'user_subscriptions', 'daily_challenges')
ORDER BY tablename, indexname;

-- ============================================================================
-- PERFORMANCE TESTING
-- ============================================================================

-- Test query performance (replace USER_ID with actual UUID):
-- EXPLAIN ANALYZE 
-- SELECT * FROM user_progress 
-- WHERE user_id = 'YOUR-USER-ID-HERE' 
-- ORDER BY completed_at DESC;

-- You should see "Index Scan using idx_user_progress_user_completed" in the output

