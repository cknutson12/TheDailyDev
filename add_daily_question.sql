-- Insert a new system design question for daily challenges
-- Replace the UUIDs and values as needed

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
    gen_random_uuid(),  -- Auto-generate UUID
    'Designing a Distributed File Storage System',
    'multiple_choice',
    '{
        "question": "You are designing a distributed file storage system similar to Google Drive. You need to ensure high availability and fault tolerance. Which strategy is MOST important for handling data replication across multiple data centers?",
        "options": [
            {"id": "a", "text": "Store all replicas in the same data center for low latency"},
            {"id": "b", "text": "Use synchronous replication to ensure all replicas are identical"},
            {"id": "c", "text": "Implement geographically distributed replicas with asynchronous replication"},
            {"id": "d", "text": "Maintain only a single master copy with no replication"}
        ],
        "diagram_ref": null,
        "image_url": "https://example.com/images/distributed-file-storage.png",
        "image_alt": "Architecture diagram showing distributed file storage system"
    }'::jsonb,
    '{
        "correct_option_id": "c",
        "correct_text": "Implement geographically distributed replicas with asynchronous replication"
    }'::jsonb,
    'For a distributed file storage system with high availability requirements, geographically distributed replicas with asynchronous replication provides the best balance of availability, fault tolerance, and performance. This approach ensures that data is available even if an entire data center fails, while asynchronous replication avoids blocking write operations. Synchronous replication (option b) would provide better consistency but at the cost of significantly increased latency for writes across multiple data centers.',
    3,  -- difficulty_level: 3 = Medium
    'System Design',
    CURRENT_DATE + INTERVAL '1 day',  -- Schedule for tomorrow (change as needed)
    NOW()
) RETURNING id;

-- After running the above, use the returned question_id to insert into daily_challenges:
-- INSERT INTO daily_challenges (id, question_id, challenge_date, created_at)
-- VALUES (gen_random_uuid(), '<question_id_from_above>', CURRENT_DATE + INTERVAL '1 day', NOW());

