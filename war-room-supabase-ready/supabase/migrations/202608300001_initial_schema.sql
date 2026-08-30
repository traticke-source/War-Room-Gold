create extension if not exists "pgcrypto";

create table public.decisions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 180),
  question text not null check (char_length(question) between 1 and 5000),
  context text, desired_outcome text, constraints text, deadline timestamptz,
  budget text, relevant_people text, worries text, current_belief text,
  status text not null default 'draft' check (status in ('draft','analyzing','complete','failed','archived')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.analysis_sessions (
  id uuid primary key default gen_random_uuid(), decision_id uuid not null references public.decisions(id) on delete cascade,
  status text not null default 'queued' check (status in ('queued','analyzing','debating','complete','failed')),
  created_at timestamptz not null default now(), completed_at timestamptz
);
create table public.agents (id uuid primary key default gen_random_uuid(), slug text not null unique, name text not null, mandate text not null, created_at timestamptz not null default now());
create table public.agent_analyses (
  id uuid primary key default gen_random_uuid(), session_id uuid not null references public.analysis_sessions(id) on delete cascade,
  agent_id uuid not null references public.agents(id), status text not null default 'queued' check (status in ('queued','analyzing','complete','failed')),
  recommendation text check (recommendation in ('GO','NO_GO','CONDITIONAL')), confidence numeric(4,3) check (confidence between 0 and 1), score smallint check (score between 0 and 100),
  key_arguments jsonb not null default '[]', risks jsonb not null default '[]', assumptions jsonb not null default '[]', unknowns jsonb not null default '[]', conditions jsonb not null default '[]', questions jsonb not null default '[]', error_message text, created_at timestamptz not null default now()
);
create table public.debates (id uuid primary key default gen_random_uuid(), session_id uuid not null references public.analysis_sessions(id) on delete cascade, topic text not null, status text not null default 'open', created_at timestamptz not null default now());
create table public.debate_messages (id uuid primary key default gen_random_uuid(), debate_id uuid not null references public.debates(id) on delete cascade, agent_id uuid references public.agents(id), round smallint not null check (round between 1 and 3), content jsonb not null, created_at timestamptz not null default now());
create table public.final_reports (id uuid primary key default gen_random_uuid(), session_id uuid not null unique references public.analysis_sessions(id) on delete cascade, recommendation text not null check (recommendation in ('GO','NO_GO','CONDITIONAL')), confidence numeric(4,3) not null check (confidence between 0 and 1), score smallint not null check (score between 0 and 100), report jsonb not null, created_at timestamptz not null default now());
create table public.decision_weights (id uuid primary key default gen_random_uuid(), decision_id uuid not null references public.decisions(id) on delete cascade, criterion text not null, weight numeric(5,2) not null check (weight between 0 and 100), unique(decision_id, criterion));
create table public.decision_outcomes (id uuid primary key default gen_random_uuid(), decision_id uuid not null unique references public.decisions(id) on delete cascade, outcome text not null, occurred_at timestamptz, rating smallint check (rating between 1 and 5), created_at timestamptz not null default now());
create table public.agent_performance (id uuid primary key default gen_random_uuid(), agent_id uuid not null references public.agents(id), user_id uuid not null references auth.users(id) on delete cascade, sample_size integer not null default 0, accuracy numeric(5,2), updated_at timestamptz not null default now(), unique(agent_id,user_id));

alter table public.decisions enable row level security; alter table public.analysis_sessions enable row level security; alter table public.agent_analyses enable row level security; alter table public.debates enable row level security; alter table public.debate_messages enable row level security; alter table public.final_reports enable row level security; alter table public.decision_weights enable row level security; alter table public.decision_outcomes enable row level security; alter table public.agent_performance enable row level security;
create policy "decision owner" on public.decisions for all using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy "session owner" on public.analysis_sessions for all using (exists(select 1 from public.decisions d where d.id=decision_id and d.user_id=auth.uid())) with check (exists(select 1 from public.decisions d where d.id=decision_id and d.user_id=auth.uid()));
create policy "analysis owner" on public.agent_analyses for all using (exists(select 1 from public.analysis_sessions s join public.decisions d on d.id=s.decision_id where s.id=session_id and d.user_id=auth.uid())) with check (exists(select 1 from public.analysis_sessions s join public.decisions d on d.id=s.decision_id where s.id=session_id and d.user_id=auth.uid()));
create policy "debate owner" on public.debates for all using (exists(select 1 from public.analysis_sessions s join public.decisions d on d.id=s.decision_id where s.id=session_id and d.user_id=auth.uid())) with check (exists(select 1 from public.analysis_sessions s join public.decisions d on d.id=s.decision_id where s.id=session_id and d.user_id=auth.uid()));
create policy "message owner" on public.debate_messages for all using (exists(select 1 from public.debates b join public.analysis_sessions s on s.id=b.session_id join public.decisions d on d.id=s.decision_id where b.id=debate_id and d.user_id=auth.uid())) with check (exists(select 1 from public.debates b join public.analysis_sessions s on s.id=b.session_id join public.decisions d on d.id=s.decision_id where b.id=debate_id and d.user_id=auth.uid()));
create policy "report owner" on public.final_reports for all using (exists(select 1 from public.analysis_sessions s join public.decisions d on d.id=s.decision_id where s.id=session_id and d.user_id=auth.uid())) with check (exists(select 1 from public.analysis_sessions s join public.decisions d on d.id=s.decision_id where s.id=session_id and d.user_id=auth.uid()));
create policy "weights owner" on public.decision_weights for all using (exists(select 1 from public.decisions d where d.id=decision_id and d.user_id=auth.uid())) with check (exists(select 1 from public.decisions d where d.id=decision_id and d.user_id=auth.uid()));
create policy "outcome owner" on public.decision_outcomes for all using (exists(select 1 from public.decisions d where d.id=decision_id and d.user_id=auth.uid())) with check (exists(select 1 from public.decisions d where d.id=decision_id and d.user_id=auth.uid()));
create policy "performance owner" on public.agent_performance for all using (auth.uid()=user_id) with check (auth.uid()=user_id);
