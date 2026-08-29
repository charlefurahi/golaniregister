# Golani SDA Resident Admin

A Vue + Supabase admin frontend for collecting resident/member information.

## Features

- Supabase email/password admin login
- Church member registration, organized in 4 sections: Taarifa Binafsi, Taarifa za Kiroho/Kanisa, Taarifa za Familia, Taarifa za Ziada
- Conditional fields: baptism year/place only show when "Umebatizwa" is Ndiyo, spouse/children only show when marital status is "Ameoa/Ameolewa", and college/institution only shows when "MwanaTUCASA" is Ndiyo
- Member search
- Member details modal ("View" button) and edit/delete
- Automatic `registered_by` and `created_at`
- Excel export (all fields, including family/children)
- Responsive dashboard
- Golani SDA navy/gold visual style

## Setup

1. Install Node.js.
2. Create a Supabase project.
3. Run `supabase/schema.sql` in Supabase SQL Editor for a **fresh** project.
   If you already have a `residents` table with real data, run
   `supabase/migration_002_extended_member_info.sql` instead — it only adds
   the new columns and never touches existing rows.
4. Create your admin users in Supabase Authentication > Users.
5. Copy `.env.example` to `.env`.
6. Put your Supabase URL and anon/publishable key in `.env`.
7. Run:

```bash
npm install
npm run dev
```

For Netlify, connect this repository and use:

- Build command: `npm run build`
- Publish directory: `dist`

## Security note

The SQL includes an `admin_users` table and RLS policies. Add only the email addresses that should be administrators before using the system with real personal data.
