-- ============================================================================
-- FEEDBACK TABLE
-- ============================================================================
-- Allows users to submit feedback that you can review in Supabase dashboard

CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('Bug Report', 'Feature Request', 'Improvement', 'Question', 'Other')),
    message TEXT NOT NULL CHECK (char_length(message) > 0 AND char_length(message) <= 2000),
    user_email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    admin_notes TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- For admin dashboard viewing (order by newest first)
CREATE INDEX IF NOT EXISTS idx_feedback_created 
ON feedback(created_at DESC);

-- For looking up user's feedback
CREATE INDEX IF NOT EXISTS idx_feedback_user 
ON feedback(user_id, created_at DESC);

-- For filtering by category
CREATE INDEX IF NOT EXISTS idx_feedback_category 
ON feedback(category, created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can INSERT their own feedback (one-way communication)
CREATE POLICY "Users can submit feedback"
ON feedback
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Note: Users CANNOT view feedback after submission (one-way only)
-- Only admins can view via service role in Supabase dashboard

-- ============================================================================
-- AUTOMATIC TIMESTAMP UPDATE
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_feedback_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER trigger_update_feedback_timestamp
BEFORE UPDATE ON feedback
FOR EACH ROW
EXECUTE FUNCTION update_feedback_updated_at();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table was created with correct structure
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'feedback'
ORDER BY ordinal_position;

-- Verify RLS policies
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
WHERE tablename = 'feedback';

-- ============================================================================
-- NOTES FOR VIEWING FEEDBACK (Admin)
-- ============================================================================

-- To view all feedback in Supabase dashboard:
-- SELECT 
--     f.id,
--     f.category,
--     f.message,
--     f.user_email,
--     f.created_at,
--     us.first_name,
--     us.last_name
-- FROM feedback f
-- LEFT JOIN user_subscriptions us ON f.user_id = us.user_id
-- ORDER BY f.created_at DESC;

-- To filter by category:
-- SELECT * FROM feedback WHERE category = 'Bug Report' ORDER BY created_at DESC;
-- SELECT * FROM feedback WHERE category = 'Feature Request' ORDER BY created_at DESC;

-- To add admin notes:
-- UPDATE feedback SET admin_notes = 'Your note here' WHERE id = 'FEEDBACK-ID-HERE';

