-- Add resources column to questions table
-- This allows questions to have an optional link to additional resources

ALTER TABLE questions 
ADD COLUMN IF NOT EXISTS resources_url TEXT;

-- Add a comment to document the column
COMMENT ON COLUMN questions.resources_url IS 'Optional URL to additional resources related to this question';

-- Example: Update an existing question with a resources URL
-- UPDATE questions 
-- SET resources_url = 'https://example.com/resource' 
-- WHERE id = 'your-question-id';

