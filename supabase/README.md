# Flux MVP — Database Reference

Schema reference and design notes for the Flux database. For setup instructions, see the [project README](../README.md#supabase-local-development).

## Schema Overview

### Custom Enum Types

| Type | Values |
|------|--------|
| `task_state` | `scheduled`, `drifted`, `completed`, `missed` |
| `task_priority` | `standard`, `important`, `must-not-miss` |
| `trigger_type` | `time`, `on_leaving_home` |

### Tables

**`users`** — User profiles and preferences.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK, auto-generated |
| `name` | text | required |
| `email` | text | required, unique |
| `preferences` | jsonb | default `{}` |
| `demo_mode` | boolean | default `false` |
| `created_at` | timestamptz | default `now()` |

**`goals`** — User goals with category and timeline.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK, auto-generated |
| `user_id` | uuid | FK → users, CASCADE |
| `title` | text | required |
| `category` | text | |
| `timeline` | text | |
| `status` | text | default `'active'` |
| `created_at` | timestamptz | default `now()` |

**`milestones`** — Weekly milestones within a goal.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK, auto-generated |
| `goal_id` | uuid | FK → goals, CASCADE |
| `week_number` | integer | required |
| `title` | text | required |
| `status` | text | default `'pending'` |
| `created_at` | timestamptz | default `now()` |

**`tasks`** — Time-blocked actions linked to goals and milestones.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK, auto-generated |
| `user_id` | uuid | FK → users, CASCADE |
| `goal_id` | uuid | FK → goals, CASCADE |
| `milestone_id` | uuid | FK → milestones, CASCADE, **nullable** |
| `title` | text | required |
| `start_time` | timestamptz | |
| `end_time` | timestamptz | |
| `state` | task_state | default `'scheduled'` |
| `priority` | task_priority | default `'standard'` |
| `trigger_type` | trigger_type | default `'time'` |
| `is_recurring` | boolean | default `false` |
| `created_at` | timestamptz | default `now()` |

**`conversations`** — AI conversation history per goal.

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK, auto-generated |
| `user_id` | uuid | FK → users, CASCADE |
| `goal_id` | uuid | FK → goals, CASCADE |
| `messages` | jsonb | default `[]`, array of `{role, text}` objects |
| `status` | text | default `'open'` |
| `created_at` | timestamptz | default `now()` |

**`demo_flags`** — Per-user demo mode controls (one row per user).

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | uuid | PK, FK → users, CASCADE |
| `virtual_now` | timestamptz | simulated current time for demo |
| `escalation_speed` | float | default `1.0` |

### Entity Relationships

```
users
 ├── goals (1:N)
 │    ├── milestones (1:N)
 │    ├── tasks (1:N)
 │    └── conversations (1:N)
 ├── tasks (1:N)
 └── demo_flags (1:1)
```

All foreign keys use `ON DELETE CASCADE` — deleting a user removes all their data.

### Indexes

Foreign key columns are indexed for query performance:

- `idx_goals_user_id`
- `idx_milestones_goal_id`
- `idx_tasks_user_id`, `idx_tasks_goal_id`, `idx_tasks_milestone_id`
- `idx_conversations_user_id`, `idx_conversations_goal_id`

## Design Decisions

- **UUIDs everywhere** — Supabase standard; avoids sequential ID leakage.
- **PostgreSQL enums** for task state/priority/trigger — enforces valid values at the DB level.
- **jsonb for preferences and messages** — flexible schema for evolving fields without migrations.
- **`demo_flags` as a separate table** — keeps demo concerns out of the main `users` table; PK is `user_id` enforcing one row per user.
- **`IF NOT EXISTS` guards** in the migration — safe to re-run without errors.

## File Structure

```
supabase/
├── config.toml                                  # Supabase project config
├── migrations/
│   └── 20260213145903_create_mvp_tables.sql     # Schema migration
├── scripts/
│   ├── seed_test_data.sql                       # Sample data for development
│   ├── truncate_tables.sql                      # Delete all rows, keep schema
│   └── drop_tables.sql                          # Drop all tables and enums
└── README.md                                    # This file
```
