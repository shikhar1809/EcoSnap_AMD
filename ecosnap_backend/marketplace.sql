-- Create Marketplace Table
create table public.marketplace (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  description text,
  cost_points int not null,
  image_url text, /* Optional: for UI */
  stock int default -1 /* -1 for infinite */
);

-- Insert Default Items
insert into public.marketplace (name, description, cost_points, stock) values
('Tree Planting', 'We will plant a tree in your name.', 500, -1),
('Eco-Badge: Guardian', 'Unlock the special Guardian badge on your profile.', 200, -1),
('10% Off BambooBrush', 'Get a discount code for BambooBrush.com', 100, 50);

-- Create Redemptions Table (History)
create table public.redemptions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) not null,
  item_id uuid references public.marketplace(id) not null,
  redeemed_at timestamp with time zone default timezone('utc'::text, now()) not null
);
