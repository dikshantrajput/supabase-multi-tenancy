# RLS Policies and Functions


## Function: `base.user_has_permissions`

The `user_has_permissions` function checks if a user has the required permissions.

### Definition
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

### Workspaces

#### `workspace isolation policy`
Restricts access to workspaces based on the workspace ID in the JWT.

```sql
CREATE POLICY "workspace isolation policy"
ON base.workspaces
AS RESTRICTIVE
TO authenticated
USING (id = (((SELECT auth.jwt())  -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid);
```

#### `select for workspaces`
Allows users with the `workspaces.read` permission to select from the `workspaces` table.

```sql
CREATE POLICY "select for workspaces"
ON base.workspaces
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  (SELECT base.user_has_permissions(ARRAY['workspaces.read'::text]) AS user_has_permissions)
);
```

#### `update for workspaces`
Allows users with the `workspaces.update` permission to update the `workspaces` table.

```sql
CREATE POLICY "update for workspaces"
ON base.workspaces
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  (SELECT base.user_has_permissions(ARRAY['workspaces.update'::text]) AS user_has_permissions)
);
```

### Users

#### `select for users`
Allows users with the `users.read` permission to select from the `users` table.

```sql
CREATE POLICY "select for users"
ON base.users
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  (SELECT base.user_has_permissions(ARRAY['users.read'::text]) AS user_has_permissions)
);
```

#### `update for users`
Allows users with the `users.update` permission to update the `users` table, or allows users to update their own records.

```sql
CREATE POLICY "update for users"
ON base.users
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  (SELECT base.user_has_permissions(ARRAY['users.update'::text]) AS user_has_permissions) OR (id = (SELECT auth.uid() AS uid))
);
```

### Workspace Users

#### `workspace isolation policy`
Restricts access to workspace users based on the workspace ID in the JWT.

```sql
CREATE POLICY "workspace isolation policy"
ON base.workspace_users
AS RESTRICTIVE
TO authenticated
USING (workspace_id = (((SELECT auth.jwt())  -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid);
```

#### `select for only workspace users`
Allows users with the `users.read` permission to select from the `workspace_users` table.

```sql
CREATE POLICY "select for only workspace users"
ON base.workspace_users
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  (SELECT base.user_has_permissions(ARRAY['users.read'::text]) AS user_has_permissions)
);
```

#### `insert for workspace users`
Allows users with the `users.create` permission to insert into the `workspace_users` table.

```sql
CREATE POLICY "insert for workspace users"
ON base.workspace_users
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  (SELECT base.user_has_permissions(ARRAY['users.create'::text]) AS user_has_permissions)
);
```

#### `update for workspace users or self`
Allows users with the `users.update` permission to update the `workspace_users` table, or allows users to update their own records.

```sql
CREATE POLICY "update for workspace users or self"
ON base.workspace_users
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  (SELECT base.user_has_permissions(ARRAY['users.update'::text]) AS user_has_permissions) OR (user_id = (SELECT auth.uid() AS uid))
);
```

#### `delete for workspace users or self`
Allows users with the `users.delete` permission to delete from the `workspace_users` table, or allows users to delete their own records.

```sql
CREATE POLICY "delete for workspace users or self"
ON base.workspace_users
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  (SELECT base.user_has_permissions(ARRAY['users.delete'::text]) AS user_has_permissions) OR (user_id = (SELECT auth.uid() AS uid))
);
```

### Workspace User Permissions

#### `select for workspace user permissions to supabase_auth_admin`
Allows the `supabase_auth_admin` role to select from the `workspace_user_permissions` table without any restrictions.

```sql
CREATE POLICY "select for workspace user permissions to supabase_auth_admin"
ON base.workspace_user_permissions
AS PERMISSIVE
FOR SELECT
TO supabase_auth_admin
USING (true);
```

## Usage

These policies ensure that only authenticated users with the appropriate permissions can access and modify data in the `workspaces`, `users`, `workspace_users`, and `workspace_user_permissions` tables. The `user_has_permissions` function is used extensively to verify user permissions dynamically, providing a robust and flexible access control mechanism.


