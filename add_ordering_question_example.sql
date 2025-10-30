-- Example SQL to insert an ordering/sequencing question into the database
-- This demonstrates the JSON structure for ordering questions

-- Step 1: Insert the ordering question into the questions table
INSERT INTO questions (
    id,
    title,
    question_type,
    content,
    correct_answer,
    explanation,
    difficulty_level,
    category,
    scheduled_date,
    created_at
) VALUES (
    gen_random_uuid(),
    'HTTP Request Lifecycle',
    'multiple_choice', -- Note: Use 'multiple_choice' if 'ordering' is not allowed in your constraint
    '{
        "question": "Arrange the steps of an HTTP request lifecycle from client to server response in the correct order",
        "ordering_items": [
            {
                "id": "step1",
                "text": "Client sends HTTP request"
            },
            {
                "id": "step2",
                "text": "Load balancer routes request"
            },
            {
                "id": "step3",
                "text": "App server handles request"
            },
            {
                "id": "step4",
                "text": "App queries database"
            },
            {
                "id": "step5",
                "text": "Server sends HTTP response"
            }
        ],
        "correct_order_ids": ["step1", "step2", "step3", "step4", "step5"]
    }'::jsonb,
    '{}'::jsonb,
    'The typical HTTP request flow: client initiates request → load balancer distributes it → app server processes → database query if needed → response sent back to client. This order ensures proper request handling and data retrieval.',
    2,
    'Networking',
    NULL,
    NOW()
) RETURNING id;

-- Step 2: Link the question to a daily challenge
-- Replace 'QUESTION_ID_HERE' with the UUID returned from the above INSERT
-- Replace '2025-11-01' with your desired date (format: YYYY-MM-DD)

INSERT INTO daily_challenges (
    question_id,
    challenge_date
) VALUES (
    'QUESTION_ID_HERE'::uuid,
    '2025-11-01'
);

-- ============================================
-- Another Example: Database Transaction Isolation Levels
-- ============================================

INSERT INTO questions (
    id,
    title,
    question_type,
    content,
    correct_answer,
    explanation,
    difficulty_level,
    category,
    scheduled_date,
    created_at
) VALUES (
    gen_random_uuid(),
    'Database Isolation Levels',
    'multiple_choice',
    '{
        "question": "Order the database isolation levels from weakest to strongest concurrency control",
        "ordering_items": [
            {
                "id": "level1",
                "text": "Read Uncommitted"
            },
            {
                "id": "level2",
                "text": "Read Committed"
            },
            {
                "id": "level3",
                "text": "Repeatable Read"
            },
            {
                "id": "level4",
                "text": "Serializable"
            }
        ],
        "correct_order_ids": ["level1", "level2", "level3", "level4"]
    }'::jsonb,
    '{}'::jsonb,
    'Read Uncommitted allows dirty reads (weakest). Read Committed prevents dirty reads but allows non-repeatable reads. Repeatable Read prevents non-repeatable reads but allows phantom reads. Serializable provides the strongest isolation by preventing all anomalies.',
    3,
    'Database',
    NULL,
    NOW()
) RETURNING id;

-- ============================================
-- Another Example: System Design Process
-- ============================================

INSERT INTO questions (
    id,
    title,
    question_type,
    content,
    correct_answer,
    explanation,
    difficulty_level,
    category,
    scheduled_date,
    created_at
) VALUES (
    gen_random_uuid(),
    'System Design Process',
    'multiple_choice',
    '{
        "question": "Arrange the typical steps of a system design interview process in order",
        "ordering_items": [
            {
                "id": "step1",
                "text": "Clarify requirements and constraints"
            },
            {
                "id": "step2",
                "text": "Calculate scale and capacity needs"
            },
            {
                "id": "step3",
                "text": "Design high-level architecture"
            },
            {
                "id": "step4",
                "text": "Deep dive into components"
            },
            {
                "id": "step5",
                "text": "Identify bottlenecks and optimize"
            }
        ],
        "correct_order_ids": ["step1", "step2", "step3", "step4", "step5"]
    }'::jsonb,
    '{}'::jsonb,
    'A proper system design process starts with understanding requirements, then calculating scale, designing the overall architecture, drilling down into specific components, and finally identifying and addressing bottlenecks.',
    2,
    'System Design',
    NULL,
    NOW()
) RETURNING id;

-- ============================================
-- Tips for Creating Ordering Questions
-- ============================================

-- 1. Keep items clear and distinct - users need to understand each step/item
-- 2. Use 4-7 items for optimal difficulty (too few is too easy, too many is overwhelming)
-- 3. Ensure there is a logical, unambiguous correct order
-- 4. Use descriptive IDs that make sense (step1, phase1, level1, etc.)
-- 5. The correct_order_ids array should contain all item IDs in the correct sequence
-- 6. Provide a detailed explanation that explains why this order is correct
-- 7. Consider using process/sequence questions for better user experience
-- 8. Example topics: request flows, state transitions, deployment steps, algorithm stages
-- 9. Avoid subjective ordering where multiple sequences could be valid
-- 10. Test the question yourself by ordering it - if it's confusing, simplify

