-- 1. Enable pgvector
create extension if not exists vector schema extensions;

-- 2. Add embeddings
alter table answers add column embedding vector(768);

-- 3. Optimize vector queries
create index on answers using ivfflat (embedding vector_cosine_ops) with (lists = 100);

-- 4. Create semantic search function
create or replace function match_answers (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  id uuid,
  question_id uuid,
  content text,
  author_id uuid,
  author_name text,
  upvotes int,
  downvotes int,
  is_accepted boolean,
  similarity float
)
language sql stable
as $$
  select
    a.id,
    a.question_id,
    a.content,
    a.author_id,
    u.full_name as author_name,
    a.upvotes,
    a.downvotes,
    a.is_accepted,
    1 - (a.embedding <=> query_embedding) as similarity
  from answers a
  join users u on u.id = a.author_id
  where 1 - (a.embedding <=> query_embedding) > match_threshold
    and (a.is_accepted = true or (a.upvotes - a.downvotes) > 0)
  order by similarity desc
  limit match_count;
$$;
