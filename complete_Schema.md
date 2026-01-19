BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- LOOKUP TABLES
-- =========================
CREATE TABLE skill_levels (
    id SMALLINT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE quiz_difficulties (
    id SMALLINT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE job_statuses (
    id SMALLINT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE event_statuses (
    id SMALLINT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE issue_statuses (
    id SMALLINT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE call_types (
    id SMALLINT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

-- =========================
-- USERS
-- =========================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL,
    dob DATE,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP
);

CREATE INDEX idx_users_active ON users(id) WHERE deleted_at IS NULL;

-- =========================
-- SKILLS
-- =========================
CREATE TABLE user_skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    skill_name TEXT NOT NULL,
    skill_level_id SMALLINT NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    updated_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
    CONSTRAINT fk_user_skills_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_user_skills_level FOREIGN KEY (skill_level_id) REFERENCES skill_levels(id),
    UNIQUE (user_id, skill_name)
);

CREATE INDEX idx_user_skills_user ON user_skills(user_id) WHERE deleted_at IS NULL;

-- =========================
-- EXPERIENCE
-- =========================
CREATE TABLE experiences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    organization TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    deleted_at TIMESTAMP,
    CONSTRAINT fk_experience_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =========================
-- EDUCATION
-- =========================
CREATE TABLE education (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    institution TEXT NOT NULL,
    degree TEXT,
    field_of_study TEXT,
    start_year INT,
    end_year INT,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    deleted_at TIMESTAMP,
    CONSTRAINT fk_education_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =========================
-- CHATS
-- =========================
CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP
);

-- =========================
-- CHAT PARTICIPANTS
-- =========================
CREATE TABLE chat_participants (
    chat_id UUID NOT NULL,
    user_id UUID NOT NULL,
    joined_at TIMESTAMP DEFAULT now(),
    PRIMARY KEY (chat_id, user_id),
    CONSTRAINT fk_chat_participants_chat FOREIGN KEY (chat_id) REFERENCES chats(id),
    CONSTRAINT fk_chat_participants_user FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =========================
-- MESSAGES (HOT TABLE)
-- =========================
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL,
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    deleted_at TIMESTAMP,
    CONSTRAINT fk_messages_chat FOREIGN KEY (chat_id) REFERENCES chats(id),
    CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id)
);

CREATE INDEX idx_messages_chat_time ON messages(chat_id, created_at DESC)
WHERE deleted_at IS NULL;

-- =========================
-- CALLS
-- =========================
CREATE TABLE calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL,
    call_type_id SMALLINT NOT NULL,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    CONSTRAINT fk_calls_chat FOREIGN KEY (chat_id) REFERENCES chats(id),
    CONSTRAINT fk_calls_type FOREIGN KEY (call_type_id) REFERENCES call_types(id)
);

-- =========================
-- QUIZZES
-- =========================
CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL,
    title TEXT NOT NULL,
    difficulty_id SMALLINT NOT NULL,
    time_limit_seconds INT NOT NULL CHECK (time_limit_seconds > 0),
    ai_generated BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    deleted_at TIMESTAMP,
    CONSTRAINT fk_quizzes_creator FOREIGN KEY (creator_id) REFERENCES users(id),
    CONSTRAINT fk_quizzes_difficulty FOREIGN KEY (difficulty_id) REFERENCES quiz_difficulties(id)
);

-- =========================
-- QUIZ ATTEMPTS
-- =========================
CREATE TABLE quiz_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_id UUID NOT NULL,
    user_id UUID NOT NULL,
    score INT CHECK (score >= 0),
    rating INT CHECK (rating BETWEEN 1 AND 5),
    attempted_at TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT fk_attempt_quiz FOREIGN KEY (quiz_id) REFERENCES quizzes(id),
    CONSTRAINT fk_attempt_user FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE (quiz_id, user_id)
);

CREATE INDEX idx_attempts_user_time ON quiz_attempts(user_id, attempted_at DESC);

-- =========================
-- JOBS
-- =========================
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    salary_range TEXT,
    status_id SMALLINT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    deleted_at TIMESTAMP,
    CONSTRAINT fk_jobs_creator FOREIGN KEY (creator_id) REFERENCES users(id),
    CONSTRAINT fk_jobs_status FOREIGN KEY (status_id) REFERENCES job_statuses(id)
);

CREATE INDEX idx_jobs_status ON jobs(status_id) WHERE deleted_at IS NULL;

-- =========================
-- EVENTS
-- =========================
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    venue TEXT,
    event_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    status_id SMALLINT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    deleted_at TIMESTAMP,
    CONSTRAINT fk_events_creator FOREIGN KEY (creator_id) REFERENCES users(id),
    CONSTRAINT fk_events_status FOREIGN KEY (status_id) REFERENCES event_statuses(id)
);

-- =========================
-- ISSUES
-- =========================
CREATE TABLE issues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status_id SMALLINT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    deleted_at TIMESTAMP,
    CONSTRAINT fk_issues_creator FOREIGN KEY (creator_id) REFERENCES users(id),
    CONSTRAINT fk_issues_status FOREIGN KEY (status_id) REFERENCES issue_statuses(id)
);

-- =========================
-- ISSUE ATTACHMENTS
-- =========================
CREATE TABLE issue_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_id UUID NOT NULL,
    file_url TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    CONSTRAINT fk_issue_attachments_issue FOREIGN KEY (issue_id) REFERENCES issues(id)
);

-- =========================
-- MATCHES
-- =========================
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    matched_user_id UUID NOT NULL,
    matched_at TIMESTAMP DEFAULT now(),
    CONSTRAINT fk_matches_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_matches_matched_user FOREIGN KEY (matched_user_id) REFERENCES users(id),
    UNIQUE (user_id, matched_user_id)
);

-- =========================
-- RLS ENABLE
-- =========================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE experiences ENABLE ROW LEVEL SECURITY;
ALTER TABLE education ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE issues ENABLE ROW LEVEL SECURITY;

COMMIT;
