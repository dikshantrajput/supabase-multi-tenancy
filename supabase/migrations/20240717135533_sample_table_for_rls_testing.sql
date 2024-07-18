-- sample table to show how to create new tables and their rls policies
-- Note that workspace_id is a FK to workspaces table and created_by_id is a FK to users table
-- Add these 2 columns in each new table as user who created the resource will have all permissions to select, update or delete on that
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
CREATE INDEX idx_settings_workspace ON base.settings (workspace_id);
CREATE INDEX idx_settings_user ON base.settings (created_by_id);

ALTER TABLE
  base.settings ENABLE ROW LEVEL SECURITY;

GRANT ALL ON base.settings to authenticated;

-- rls policies
-- user can do manipulation on resource only on the data that is of their workspace
-- select -> If have permissions to read and the data created by them 
-- insert -> If have permissions to create
-- update -> If have permissions to update and the data created by them
-- delete -> If have permissions to delete and the data created by them

-- Assuming permissions looks like this.
-- FOR SELECT -> <table_name>.read
-- FOR INSERT -> <table_name>.create
-- FOR UPDATE -> <table_name>.update
-- FOR DELETE -> <table_name>.delete

-- Restrictive policy for restricting
CREATE POLICY "workspace isolation policy"
ON base.settings
as RESTRICTIVE
to authenticated
USING (workspace_id = (((SELECT auth.jwt())  -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid);

create policy "select policy"
ON base.settings
as PERMISSIVE
for SELECT
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['settings.read'::text]) AS user_has_permissions) OR (created_by_id = ( SELECT auth.uid() AS uid))
);

create policy "insert policy"
ON base.settings
as PERMISSIVE
for INSERT
to authenticated
with check (
  ( SELECT base.user_has_permissions(ARRAY['settings.create'::text]) AS user_has_permissions)
);

create policy "update policy"
ON base.settings
as PERMISSIVE
for UPDATE
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['settings.update'::text]) AS user_has_permissions) OR (created_by_id = ( SELECT auth.uid() AS uid))
);

create policy "delete policy"
ON base.settings
as PERMISSIVE
for DELETE
to authenticated
using (
  ( SELECT base.user_has_permissions(ARRAY['settings.delete'::text]) AS user_has_permissions) OR (created_by_id = ( SELECT auth.uid() AS uid))
);
