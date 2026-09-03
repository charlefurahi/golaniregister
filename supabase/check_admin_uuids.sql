-- Run this to see which of the 6 candidate admin UUIDs actually
-- exist as real Supabase Auth accounts right now.
select
  candidate.user_id,
  u.email,
  (u.id is not null) as exists_in_auth_users
from (values
  ('db574d80-538b-4efb-9325-28f0bb698edc'::uuid),
  ('c7778d02-c5de-4e71-b212-c848101635f3'::uuid),
  ('bc29c850-b728-4706-9794-309fa69b8460'::uuid),
  ('683106ea-494d-46c9-8836-9f0ef52beb69'::uuid),
  ('44be2dfc-d902-4e31-8b5e-05252dbf5ec1'::uuid),
  ('e7e3003c-013c-4bd7-b801-797781fb5fff'::uuid)
) as candidate(user_id)
left join auth.users u on u.id = candidate.user_id
order by exists_in_auth_users, candidate.user_id;
