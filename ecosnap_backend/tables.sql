-- Create Questions Table
create table public.questions (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  user_id uuid references auth.users(id) on delete cascade not null, -- Assuming auth.users exists, else text
  user_name text,
  title text not null,
  content text not null,
  category text default 'General',
  city text,
  upvotes int default 0,
  answer_count int default 0
);

-- Create Answers Table
create table public.answers (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  question_id uuid references public.questions(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete cascade not null, -- Assuming auth.users exists
  user_name text,
  content text not null,
  upvotes int default 0,
  is_expert boolean default false
);

-- Enable Row Level Security (RLS) - Optional for MVP but good practice
alter table public.questions enable row level security;
alter table public.answers enable row level security;

-- Policies (Allow all for MVP)
create policy "Public questions are viewable by everyone." on public.questions for select using (true);
create policy "Users can insert their own questions." on public.questions for insert with check (true);
create policy "Public answers are viewable by everyone." on public.answers for select using (true);
create policy "Users can insert their own answers." on public.answers for insert with check (true);
