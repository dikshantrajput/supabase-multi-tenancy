# Database Policies and Functions README

This document explains the database functions and policies implemented for managing access control and permissions in our application.

## Table of Contents

1. [Functions](#functions)
   - [user_has_permissions](#function-user_has_permissions)
2. [Policies](#policies)
   - [Workspaces Policies](#workspaces-policies)
   - [Users Policies](#users-policies)
   - [Workspace Users Policies](#workspace-users-policies)
   - [Workspace User Permissions Policies](#workspace-user-permissions-policies)

## Functions

### Function: user_has_permissions

This function checks if a user has the requested permissions based on their JWT token.

```sql
CREATE OR REPLACE FUNCTION base.user_has_permissions(requested_permissions TEXT[])
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER STABLE
AS $$
DECLARE
 user_permissions JSONB;
BEGIN
  -- Get user permissions from JWT
  user_permissions := (auth.jwt() ->> 'user_permissions')::jsonb;
  -- Return false if user_permissions is null
  IF user_permissions IS NULL THEN
    RETURN false;
  END IF;
  -- Check if any requested permission exists in user permissions
  RETURN EXISTS (
    SELECT 1
    FROM jsonb_array_elements_text(user_permissions) AS user_permission
    WHERE user_permission = ANY(requested_permissions)
  );
END;
$$;
```

## Policies

### Workspaces Policies

#### Workspace Isolation Policy

Restricts access to workspaces based on the user's workspace_id in their JWT token.

```sql
CREATE POLICY "workspace isolation policy"
ON base.workspaces
as RESTRICTIVE
to authenticated
USING (id = (((SELECT auth.jwt()) -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid);
```

#### Select for Workspaces

Allows authenticated users with 'workspaces.read' permission to select workspaces.

```sql
create policy "select for workspaces"
on "base"."workspaces"
as PERMISSIVE
for SELECT
to authenticated
using (
 ( SELECT base.user_has_permissions(ARRAY['workspaces.read'::text]) AS user_has_permissions)
);
```

#### Update for Workspaces

Allows authenticated users with 'workspaces.update' permission to update workspaces.

```sql
create policy "update for workspaces"
on "base"."workspaces"
as PERMISSIVE
for UPDATE
to authenticated
using (
 ( SELECT base.user_has_permissions(ARRAY['workspaces.update'::text]) AS user_has_permissions)
);
```

#### Insert for Workspaces

Allows only service_role to insert new workspaces.

```sql
create policy "insert for workspaces"
on "base"."workspaces"
as PERMISSIVE
for INSERT
to service_role
WITH CHECK (
 true
);
```

### Users Policies

#### Select for Users

Allows authenticated users with 'users.read' permission to select users.

```sql
create policy "select for users"
on "base"."users"
as PERMISSIVE
for SELECT
to authenticated
using (
 ( SELECT base.user_has_permissions(ARRAY['users.read'::text]) AS user_has_permissions)
);
```

#### Update for Users

Allows authenticated users with 'users.update' permission or the user themselves to update user information.

```sql
create policy "update for users"
on "base"."users"
as PERMISSIVE
for UPDATE
to authenticated
using (
 ( SELECT base.user_has_permissions(ARRAY['users.update'::text]) AS user_has_permissions) OR (id = ( SELECT auth.uid() AS uid))
);
```

### Workspace Users Policies

#### Workspace Isolation Policy

Restricts access to workspace users based on the user's workspace_id in their JWT token.

```sql
CREATE POLICY "workspace isolation policy"
ON base.workspace_users
as RESTRICTIVE
to authenticated
USING (workspace_id = (((SELECT auth.jwt()) -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid);
```

#### Select for Workspace Users

Allows authenticated users with 'users.read' permission to select workspace users.

```sql
create policy "select for only workspace users"
on "base"."workspace_users"
as PERMISSIVE
for SELECT
to authenticated
using (
 ( SELECT base.user_has_permissions(ARRAY['users.read'::text]) AS user_has_permissions)
);
```

#### Insert for Workspace Users

Allows authenticated users with 'users.create' permission to insert new workspace users.

```sql
create policy "insert for workspace users"
on "base"."workspace_users"
as PERMISSIVE
for INSERT
to authenticated
with check (
 ( SELECT base.user_has_permissions(ARRAY['users.create'::text]) AS user_has_permissions)
);
```

#### Update for Workspace Users

Allows authenticated users with 'users.update' permission or the user themselves to update workspace user information.

```sql
create policy "update for workspace users or self"
on "base"."workspace_users"
as PERMISSIVE
for UPDATE
to authenticated
using (
 ( SELECT base.user_has_permissions(ARRAY['users.update'::text]) AS user_has_permissions) OR (user_id = ( SELECT auth.uid() AS uid))
);
```

#### Delete for Workspace Users

Allows authenticated users with 'users.delete' permission or the user themselves to delete workspace user information.

```sql
create policy "delete for workspace users or self"
on "base"."workspace_users"
as PERMISSIVE
for DELETE
to authenticated
using (
 ( SELECT base.user_has_permissions(ARRAY['users.delete'::text]) AS user_has_permissions) OR (user_id = ( SELECT auth.uid() AS uid))
);
```

### Workspace User Permissions Policies

#### Select for Workspace User Permissions

Allows supabase_auth_admin to select workspace user permissions.

```sql
create policy "select for workspace user permissions to supabase_auth_admin"
on "base"."workspace_user_permissions"
as PERMISSIVE
for SELECT
to supabase_auth_admin
using (
 true
);
```
