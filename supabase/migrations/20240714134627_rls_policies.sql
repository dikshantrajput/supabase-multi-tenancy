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

-- workspaces policies
-- -- -- -- -- 
CREATE POLICY "workspace isolation policy"
ON base.workspaces
as RESTRICTIVE
to authenticated
USING (id = (((SELECT auth.jwt())  -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid);


create policy "select for workspaces"
on "base"."workspaces"
as PERMISSIVE
for SELECT
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['workspaces.read'::text]) AS user_has_permissions)
);


create policy "update for workspaces"
on "base"."workspaces"
as PERMISSIVE
for UPDATE
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['workspaces.update'::text]) AS user_has_permissions)
);



-- users policies
-- -- -- -- -- 
create policy "select for users"
on "base"."users"
as PERMISSIVE
for SELECT
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['users.read'::text]) AS user_has_permissions)
);

-- any user with permissions or self
create policy "update for users"
on "base"."users"
as PERMISSIVE
for UPDATE
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['users.update'::text]) AS user_has_permissions) OR (id = ( SELECT auth.uid() AS uid))
);




-- workspace_users policies
-- -- -- -- -- 
CREATE POLICY "workspace isolation policy"
ON base.workspace_users
as RESTRICTIVE
to authenticated
USING (workspace_id = (((SELECT auth.jwt())  -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid);


create policy "select for only workspace users"
on "base"."workspace_users"
as PERMISSIVE
for SELECT
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['users.read'::text]) AS user_has_permissions)
);

create policy "insert for workspace users"
on "base"."workspace_users"
as PERMISSIVE
for INSERT
to authenticated
with check (
  ( SELECT base.user_has_permissions(ARRAY['users.create'::text]) AS user_has_permissions)
);

-- update should be enabled for the current user
create policy "update for workspace users or self"
on "base"."workspace_users"
as PERMISSIVE
for UPDATE
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['users.update'::text]) AS user_has_permissions) OR (user_id = ( SELECT auth.uid() AS uid))
);

-- delete should be enabled for the current user
create policy "delete for workspace users or self"
on "base"."workspace_users"
as PERMISSIVE
for DELETE
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['users.delete'::text]) AS user_has_permissions) OR (user_id = ( SELECT auth.uid() AS uid))
);


-- workspace_user_permissions policies
create policy "select for workspace user permissions to supabase_auth_admin"
on "base"."workspace_user_permissions"
as PERMISSIVE
for SELECT
to supabase_auth_admin
using (
  true
);
