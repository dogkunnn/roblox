<h1>set up</h1>
<h2>db</h2>

```js
CREATE TABLE IF NOT EXISTS public.players (
  username text PRIMARY KEY,
  cash int4,
  playercount int4,
  servername text,
  status text
);
```
