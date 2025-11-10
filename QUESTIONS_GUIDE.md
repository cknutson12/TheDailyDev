# Questions Guide - The Daily Dev

## Overview

The Daily Dev supports three types of questions, each determined by the structure of the `content` JSONB field in the database. The app automatically detects the question type based on which fields are present.

---

## Question Types

### 1. Multiple Choice Questions
**Detected when:** `content.options` array exists

**Fields:**
- `content.question` - The question text
- `content.options` - Array of answer choices
- `content.imageUrl` (optional) - URL to an image
- `content.imageAlt` (optional) - Alt text for the image
- `correct_answer.correct_option_id` - ID of the correct option

**Example Insert:**

```sql
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
    'Load Balancing Strategy',
    '{
        "question": "Which load balancing algorithm distributes requests based on the current number of active connections to each server?",
        "options": [
            {"id": "a", "text": "Round Robin"},
            {"id": "b", "text": "Least Connections"},
            {"id": "c", "text": "IP Hash"},
            {"id": "d", "text": "Random"}
        ],
        "imageUrl": "",
        "imageAlt": ""
    }'::jsonb,
    '{"correct_option_id": "b"}'::jsonb,
    'Least Connections algorithm routes traffic to the server with the fewest active connections, making it ideal for scenarios where request processing time varies significantly.',
    2,
    'Load Balancing',
    NOW()
);
```

**With Image Example:**

```sql
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
    'Database Architecture',
    '{
        "question": "Based on the diagram, which component handles read replicas?",
        "options": [
            {"id": "a", "text": "Primary Database"},
            {"id": "b", "text": "Read Replica Pool"},
            {"id": "c", "text": "Cache Layer"},
            {"id": "d", "text": "Load Balancer"}
        ],
        "imageUrl": "https://your-bucket.supabase.co/storage/v1/object/public/question-images/db-architecture.png",
        "imageAlt": "Database architecture diagram showing primary database, read replicas, and cache layer"
    }'::jsonb,
    '{"correct_option_id": "b"}'::jsonb,
    'Read replicas handle read-only queries, reducing load on the primary database.',
    2,
    'Databases',
    NOW()
);
```

---

### 2. Matching Questions (Drag & Drop)
**Detected when:** `content.matching_items` array exists

**Fields:**
- `content.question` - The question text
- `content.matching_items` - Array of items to match (some draggable, some targets)
- `content.correct_matches` - Array of correct source→target pairs
- `content.imageUrl` (optional) - URL to an image
- `content.imageAlt` (optional) - Alt text for the image
- `correct_answer.correct_option_id` - Can be "all" or specific ID

**Example Insert:**

```sql
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
    'CAP Theorem Properties',
    '{
        "question": "Match each database system to its CAP theorem trade-off:",
        "matching_items": [
            {"id": "cassandra", "text": "Cassandra", "is_draggable": true},
            {"id": "mongodb", "text": "MongoDB", "is_draggable": true},
            {"id": "postgresql", "text": "PostgreSQL", "is_draggable": true},
            {"id": "ap", "text": "Availability + Partition Tolerance (AP)", "is_draggable": false},
            {"id": "cp", "text": "Consistency + Partition Tolerance (CP)", "is_draggable": false},
            {"id": "ca", "text": "Consistency + Availability (CA)", "is_draggable": false}
        ],
        "correct_matches": [
            {"source_id": "cassandra", "target_id": "ap"},
            {"source_id": "mongodb", "target_id": "cp"},
            {"source_id": "postgresql", "target_id": "ca"}
        ],
        "imageUrl": "",
        "imageAlt": ""
    }'::jsonb,
    '{"correct_option_id": "all"}'::jsonb,
    'Cassandra prioritizes availability and partition tolerance (AP), MongoDB prioritizes consistency and partition tolerance (CP), and PostgreSQL in a single-node setup prioritizes consistency and availability (CA).',
    3,
    'Distributed Systems',
    NOW()
);
```

**Matching Question Structure:**
- **Draggable items** (`is_draggable: true`): Items users drag
- **Target zones** (`is_draggable: false`): Drop zones where items are placed
- **Correct matches**: Define which draggable items go to which targets

---

### 3. Ordering/Sequencing Questions
**Detected when:** `content.ordering_items` array exists

**Fields:**
- `content.question` - The question text
- `content.ordering_items` - Array of items to be ordered
- `content.correct_order_ids` - Array of IDs in the correct order
- `content.imageUrl` (optional) - URL to an image
- `content.imageAlt` (optional) - Alt text for the image
- `correct_answer.correct_option_id` - Can be "all" or specific ID

**Example Insert:**

```sql
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
    'HTTP Request Lifecycle',
    '{
        "question": "Arrange the following steps in the correct order of an HTTP request:",
        "ordering_items": [
            {"id": "dns", "text": "DNS Resolution"},
            {"id": "tcp", "text": "TCP Handshake"},
            {"id": "tls", "text": "TLS Negotiation"},
            {"id": "request", "text": "HTTP Request Sent"},
            {"id": "response", "text": "HTTP Response Received"}
        ],
        "correct_order_ids": ["dns", "tcp", "tls", "request", "response"],
        "imageUrl": "",
        "imageAlt": ""
    }'::jsonb,
    '{"correct_option_id": "all"}'::jsonb,
    'An HTTP request follows this sequence: First, DNS resolves the domain to an IP. Then, a TCP connection is established. For HTTPS, TLS negotiation occurs. Finally, the HTTP request is sent and response is received.',
    2,
    'Networking',
    NOW()
);
```

**Ordering Question Notes:**
- Items are initially shown in a random or scrambled order
- Users drag to reorder them
- The `correct_order_ids` array defines the exact sequence

---

## Scheduling Questions

After inserting a question, schedule it for a specific day using the `daily_challenges` table:

```sql
-- Schedule a question for a specific date
INSERT INTO daily_challenges (
    id,
    question_id,
    challenge_date,
    created_at
) VALUES (
    gen_random_uuid(),
    'YOUR-QUESTION-UUID-HERE',
    '2025-11-15',  -- YYYY-MM-DD format
    NOW()
);
```

**Important:** Each date can only have ONE question (enforced by UNIQUE constraint on `challenge_date`).

---

## Question Schema Reference

### Questions Table

```sql
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content JSONB NOT NULL,
    correct_answer JSONB NOT NULL,
    explanation TEXT,
    difficulty_level INTEGER NOT NULL CHECK (difficulty_level BETWEEN 1 AND 5),
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Daily Challenges Table

```sql
CREATE TABLE daily_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    challenge_date DATE NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Content JSONB Structure

### Multiple Choice
```json
{
  "question": "Question text here",
  "options": [
    {"id": "a", "text": "Option A"},
    {"id": "b", "text": "Option B"},
    {"id": "c", "text": "Option C"},
    {"id": "d", "text": "Option D"}
  ],
  "imageUrl": "optional-image-url",
  "imageAlt": "optional-alt-text"
}
```

### Matching
```json
{
  "question": "Question text here",
  "matching_items": [
    {"id": "item1", "text": "Draggable Item 1", "is_draggable": true},
    {"id": "item2", "text": "Draggable Item 2", "is_draggable": true},
    {"id": "zone1", "text": "Target Zone 1", "is_draggable": false},
    {"id": "zone2", "text": "Target Zone 2", "is_draggable": false}
  ],
  "correct_matches": [
    {"source_id": "item1", "target_id": "zone1"},
    {"source_id": "item2", "target_id": "zone2"}
  ],
  "imageUrl": "optional-image-url",
  "imageAlt": "optional-alt-text"
}
```

### Ordering
```json
{
  "question": "Question text here",
  "ordering_items": [
    {"id": "step1", "text": "First step"},
    {"id": "step2", "text": "Second step"},
    {"id": "step3", "text": "Third step"}
  ],
  "correct_order_ids": ["step1", "step2", "step3"],
  "imageUrl": "optional-image-url",
  "imageAlt": "optional-alt-text"
}
```

---

## Correct Answer JSONB Structure

### Multiple Choice
```json
{"correct_option_id": "b"}
```

### Matching & Ordering
```json
{"correct_option_id": "all"}
```

*Note: For matching and ordering questions, the actual correct answer is defined in the `content` field (`correct_matches` or `correct_order_ids`).*

---

## Difficulty Levels

- **1** - Beginner
- **2** - Intermediate
- **3** - Advanced
- **4** - Expert
- **5** - Master

---

## Categories (Examples)

- Caching
- Load Balancing
- Databases
- Distributed Systems
- Networking
- API Design
- Security
- Scalability
- Microservices
- Message Queues

*Categories are free-form text - use whatever makes sense for your content.*

---

## Tips for Creating Questions

1. **Keep titles concise** - They appear as headers
2. **Make questions clear** - Avoid ambiguity
3. **Provide good explanations** - Help users learn from mistakes
4. **Use images when helpful** - Visual aids improve understanding
5. **Test your questions** - Make sure the correct answer is actually correct!
6. **Balance difficulty** - Mix easy and hard questions
7. **Vary question types** - Keep users engaged with different formats

---

## Quick Reference: Insert Template

```sql
-- Multiple Choice
INSERT INTO questions (id, title, content, correct_answer, explanation, difficulty_level, category, created_at)
VALUES (gen_random_uuid(), 'TITLE', '{"question":"Q","options":[{"id":"a","text":"A"}]}'::jsonb, '{"correct_option_id":"a"}'::jsonb, 'EXPLANATION', 1, 'CATEGORY', NOW());

-- Matching
INSERT INTO questions (id, title, content, correct_answer, explanation, difficulty_level, category, created_at)
VALUES (gen_random_uuid(), 'TITLE', '{"question":"Q","matching_items":[{"id":"i1","text":"I1","is_draggable":true}],"correct_matches":[{"source_id":"i1","target_id":"t1"}]}'::jsonb, '{"correct_option_id":"all"}'::jsonb, 'EXPLANATION', 1, 'CATEGORY', NOW());

-- Ordering
INSERT INTO questions (id, title, content, correct_answer, explanation, difficulty_level, category, created_at)
VALUES (gen_random_uuid(), 'TITLE', '{"question":"Q","ordering_items":[{"id":"s1","text":"S1"}],"correct_order_ids":["s1"]}'::jsonb, '{"correct_option_id":"all"}'::jsonb, 'EXPLANATION', 1, 'CATEGORY', NOW());

-- Schedule it
INSERT INTO daily_challenges (id, question_id, challenge_date, created_at)
VALUES (gen_random_uuid(), 'QUESTION-UUID', '2025-11-15', NOW());
```

---

## Need Help?

- Check existing questions in your database for examples
- Test questions in the app before scheduling them
- Use the Supabase SQL Editor for easy insertion and testing

