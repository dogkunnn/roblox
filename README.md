# setup
### ให้สิทธิ์ RLS Policy
```
-- 1. Enable Row Level Security for the 'players' table
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

-- 2. Drop any existing policies that might conflict (optional, but good for a clean slate)
DROP POLICY IF EXISTS "Allow all access for all users" ON public.players;

-- 3. Create the new policy: "Allow all access for all users"
CREATE POLICY "Allow all access for all users"
ON public.players
FOR ALL -- Applies to SELECT, INSERT, UPDATE, DELETE
TO anon, authenticated -- Corrected: Use role names directly, without 'public.' prefix
USING (true) -- Condition is always true, so access is always granted
WITH CHECK (true); -- Condition for writes is always true, so writes are always allowed
```

### สร้างตรางฐานข้อมูลและcolumn
```
CREATE TABLE public.players (
  username TEXT PRIMARY KEY,
  cash INTEGER,
  playercount INTEGER,
  status TEXT,
  last_online TIMESTAMPTZ,
  is_farming BOOLEAN,
  kick_player BOOLEAN
);

```

### Link
[supabase](https://supabase.com)

### Environment
```SUPABASE_API_KEY```

### get api 
```API Docs>API settings```
```(https://youapi.supabase.co)```


