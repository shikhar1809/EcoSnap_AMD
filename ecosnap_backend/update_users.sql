-- Add carbon_saved column to users table
alter table public.users 
add column if not exists carbon_saved float default 0.0;
