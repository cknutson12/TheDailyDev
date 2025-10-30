-- Example SQL to insert a matching question into the database
-- This demonstrates the JSON structure for matching questions

-- Step 1: Insert the matching question into the questions table
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
    'Caching Strategies',
    'multiple_choice',
    '{
        "question": "Match each caching strategy to its best use case",
        "matching_items": [
            {
                "id": "cache1",
                "text": "Write-through cache",
                "is_draggable": true
            },
            {
                "id": "cache2",
                "text": "Write-behind cache",
                "is_draggable": true
            },
            {
                "id": "cache3",
                "text": "Read-through cache",
                "is_draggable": true
            },
            {
                "id": "use1",
                "text": "High write frequency, eventual consistency OK",
                "is_draggable": false
            },
            {
                "id": "use2",
                "text": "High read frequency, critical data consistency",
                "is_draggable": false
            },
            {
                "id": "use3",
                "text": "Lazy loading pattern for cache misses",
                "is_draggable": false
            }
        ],
        "correct_matches": [
            {
                "source_id": "cache1",
                "target_id": "use2"
            },
            {
                "source_id": "cache2",
                "target_id": "use1"
            },
            {
                "source_id": "cache3",
                "target_id": "use3"
            }
        ]
    }'::jsonb,
    '{}'::jsonb,
    'Write-through cache ensures data consistency by writing to both cache and database simultaneously, making it ideal for scenarios where data consistency is critical. Write-behind cache improves write performance by asynchronously writing to the database, which works well when eventual consistency is acceptable. Read-through cache implements lazy loading, fetching data from the database only on cache misses.',
    3,
    'Caching',
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
-- Another Example: Load Balancing Algorithms
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
    'Load Balancing Algorithms',
    'multiple_choice',
    '{
        "question": "Match each load balancing algorithm to its primary characteristic",
        "matching_items": [
            {
                "id": "alg1",
                "text": "Round Robin",
                "is_draggable": true
            },
            {
                "id": "alg2",
                "text": "Least Connections",
                "is_draggable": true
            },
            {
                "id": "alg3",
                "text": "IP Hash",
                "is_draggable": true
            },
            {
                "id": "alg4",
                "text": "Weighted Round Robin",
                "is_draggable": true
            },
            {
                "id": "char1",
                "text": "Routes based on client IP for session persistence",
                "is_draggable": false
            },
            {
                "id": "char2",
                "text": "Distributes requests evenly in circular fashion",
                "is_draggable": false
            },
            {
                "id": "char3",
                "text": "Considers server capacity with weight assignments",
                "is_draggable": false
            },
            {
                "id": "char4",
                "text": "Routes to server with fewest active connections",
                "is_draggable": false
            }
        ],
        "correct_matches": [
            {
                "source_id": "alg1",
                "target_id": "char2"
            },
            {
                "source_id": "alg2",
                "target_id": "char4"
            },
            {
                "source_id": "alg3",
                "target_id": "char1"
            },
            {
                "source_id": "alg4",
                "target_id": "char3"
            }
        ]
    }'::jsonb,
    '{}'::jsonb,
    'Round Robin distributes requests in a simple circular pattern. Least Connections routes to the server with the fewest active connections, which is useful for long-lived connections. IP Hash ensures session persistence by routing the same client to the same server. Weighted Round Robin allows you to assign different capacities to servers based on their resources.',
    2,
    'Load Balancing',
    NULL,
    NOW()
) RETURNING id;

-- ============================================
-- Tips for Creating Matching Questions
-- ============================================

-- 1. Keep draggable items (is_draggable: true) concise - these are the items users will drag
-- 2. Target items (is_draggable: false) can be longer descriptions or use cases
-- 3. Use 3-5 pairs for optimal difficulty
-- 4. Ensure IDs are unique within the question
-- 5. The correct_matches array defines the right pairings
-- 6. Always provide a detailed explanation that covers all matches

