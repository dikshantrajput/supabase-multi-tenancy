# Guide: Creating a Sample Table with RLS Policies

This guide demonstrates how to create a new table with Row Level Security (RLS) policies in a multi-tenant architecture using PostgreSQL and Supabase.

## Table Structure

We'll create a `settings` table in the `base` schema with the following structure:

```sql
CREATE TABLE base.settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    settings_json JSONB,
    workspace_id UUID NOT NULL,
    created_by_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    CONSTRAINT fk_user FOREIGN KEY (created_by_id) REFERENCES base.users (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES base.workspaces (id) ON DELETE CASCADE ON UPDATE CASCADE
);
```

## Indexes

Create indexes for better query performance:

```sql
CREATE INDEX idx_settings_workspace ON base.settings (workspace_id);
CREATE INDEX idx_settings_user ON base.settings (created_by_id);
```

## Enable RLS and Grant Permissions

Enable Row Level Security and grant permissions to authenticated users:

```sql
ALTER TABLE base.settings ENABLE ROW LEVEL SECURITY;
GRANT ALL ON base.settings to authenticated;
```

## RLS Policies

### Workspace Isolation Policy

This restrictive policy ensures data isolation between workspaces:

```sql
CREATE POLICY "workspace isolation policy"
ON base.settings
AS RESTRICTIVE
TO authenticated
USING (workspace_id = (((SELECT auth.jwt()) -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid);
```

### Select Policy

Allows users to read data if they have the required permission or if they created the data:

```sql
CREATE POLICY "select policy"
ON base.settings
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
    (SELECT base.user_has_permissions(ARRAY['settings.read'::text]) AS user_has_permissions)
    OR (created_by_id = (SELECT auth.uid() AS uid))
);
```

### Insert Policy

Allows users to insert data if they have the required permission:

```sql
CREATE POLICY "insert policy"
ON base.settings
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
    (SELECT base.user_has_permissions(ARRAY['settings.create'::text]) AS user_has_permissions)
);
```

### Update Policy

Allows users to update data if they have the required permission or if they created the data:

```sql
CREATE POLICY "update policy"
ON base.settings
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
    (SELECT base.user_has_permissions(ARRAY['settings.update'::text]) AS user_has_permissions)
    OR (created_by_id = (SELECT auth.uid() AS uid))
);
```

### Delete Policy

Allows users to delete data if they have the required permission or if they created the data:

```sql
CREATE POLICY "delete policy"
ON base.settings
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
    (SELECT base.user_has_permissions(ARRAY['settings.delete'::text]) AS user_has_permissions)
    OR (created_by_id = (SELECT auth.uid() AS uid))
);
```

## Notes

- The `workspace_id` is a foreign key to the `workspaces` table.
- The `created_by_id` is a foreign key to the `users` table.
- Include these two columns in each new table to manage permissions effectively.
- The user who created the resource will have all permissions to select, update, or delete that resource.
- Permissions are structured as `<table_name>.<action>`, e.g., `settings.read`, `settings.create`, etc.
- The `base.user_has_permissions` function is used to check user permissions.

By following this guide, you can create new tables with appropriate RLS policies that maintain data isolation and proper access control in your multi-tenant application.