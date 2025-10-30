-- Add 'matching' to the allowed question_type values
-- Run this in your Supabase SQL editor before inserting matching questions

ALTER TABLE questions DROP CONSTRAINT IF EXISTS questions_question_type_check;

ALTER TABLE questions ADD CONSTRAINT questions_question_type_check 
    CHECK (question_type IN ('multiple_choice', 'matching', 'true_false', 'short_answer'));

-- Note: Adjust the allowed types in the CHECK constraint above based on your actual allowed values

