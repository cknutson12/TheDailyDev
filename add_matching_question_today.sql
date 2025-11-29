-- Matching Question for Today (2025-11-15)
-- Topic: Database Replication Strategies

-- Step 1: Insert the matching question
WITH new_question AS (
    INSERT INTO questions (
        id,
        title,
        content,
        correct_answer,
        explanation,
        difficulty_level,
        category,
        created_at
    ) VALUES (
        gen_random_uuid(),
        'Database Replication Strategies',
        '{
            "question": "Match each database replication strategy to its primary characteristic:",
            "matching_items": [
                {
                    "id": "master_slave",
                    "text": "Master-Slave Replication",
                    "is_draggable": true
                },
                {
                    "id": "master_master",
                    "text": "Master-Master Replication",
                    "is_draggable": true
                },
                {
                    "id": "multi_master",
                    "text": "Multi-Master Replication",
                    "is_draggable": true
                },
                {
                    "id": "read_replicas",
                    "text": "Read Replicas",
                    "is_draggable": true
                },
                {
                    "id": "char1",
                    "text": "One-way replication, writes only to master",
                    "is_draggable": false
                },
                {
                    "id": "char2",
                    "text": "Bidirectional replication between two masters",
                    "is_draggable": false
                },
                {
                    "id": "char3",
                    "text": "Distributed writes across multiple masters",
                    "is_draggable": false
                },
                {
                    "id": "char4",
                    "text": "Scales read operations, reduces master load",
                    "is_draggable": false
                }
            ],
            "correct_matches": [
                {
                    "source_id": "master_slave",
                    "target_id": "char1"
                },
                {
                    "source_id": "master_master",
                    "target_id": "char2"
                },
                {
                    "source_id": "multi_master",
                    "target_id": "char3"
                },
                {
                    "source_id": "read_replicas",
                    "target_id": "char4"
                }
            ],
            "imageUrl": "",
            "imageAlt": ""
        }'::jsonb,
        '{"correct_option_id": "all"}'::jsonb,
        'Master-Slave replication provides one-way replication where all writes go to the master and are replicated to slaves. Master-Master replication allows bidirectional replication between two database servers, enabling writes to either master. Multi-Master replication distributes writes across multiple master nodes, providing high availability and write scalability. Read Replicas are copies of the master database that handle read queries, significantly reducing load on the primary database and improving read performance.',
        3,
        'Databases',
        NOW()
    )
    RETURNING id
)
-- Step 2: Schedule the question for today (2025-11-15)
INSERT INTO daily_challenges (
    id,
    question_id,
    challenge_date,
    created_at
)
SELECT 
    gen_random_uuid(),
    new_question.id,
    '2025-11-15'::date,
    NOW()
FROM new_question;

