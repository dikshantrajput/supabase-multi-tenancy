-- workspaces table start
CREATE TABLE base.workspaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  extra_data JSONB,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

COMMENT ON COLUMN base.workspaces.extra_data IS 'Add extra details for workspaces';

CREATE UNIQUE INDEX idx_workspaces_slug ON base.workspaces (slug);

ALTER TABLE
  base.workspaces ENABLE ROW LEVEL SECURITY;

GRANT ALL ON base.workspaces to authenticated;
GRANT INSERT ON base.workspaces TO service_role;

-- workspaces table end
-- users table start
CREATE TABLE base.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  extra_data JSONB,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

COMMENT ON COLUMN base.users.extra_data IS 'Add extra details for users';

CREATE UNIQUE INDEX idx_users_email ON base.users (email);

ALTER TABLE
  base.users ENABLE ROW LEVEL SECURITY;

GRANT ALL ON base.users TO authenticated;

-- users table end
-- workspace_users table start
CREATE TABLE base.workspace_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL,
  user_id UUID NOT NULL,
  extra_data JSONB,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES base.workspaces (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES base.users (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX idx_workspace_users_workspace_user ON base.workspace_users (workspace_id, user_id);

ALTER TABLE
  base.workspace_users ENABLE ROW LEVEL SECURITY;

GRANT ALL ON base.workspace_users TO authenticated;

-- workspace_users table end
-- workspace_roles table start
-- CREATE TABLE base.workspace_roles (
--   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   workspace_id UUID NOT NULL,
--   role_name VARCHAR(50) NOT NULL,
--   permissions JSONB,
--   created_at TIMESTAMP DEFAULT now(),
--   updated_at TIMESTAMP DEFAULT now(),
--   CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES base.workspaces (id) ON DELETE CASCADE ON UPDATE CASCADE
-- );
-- CREATE UNIQUE INDEX idx_workspace_roles ON base.workspace_roles (workspace_id, role_name);
-- ALTER TABLE
--   base.workspace_roles ENABLE ROW LEVEL SECURITY;
-- GRANT ALL ON base.workspace_roles TO authenticated;
-- -- workspace_roles table end
-- workspace_user_roles table start
-- CREATE TABLE base.workspace_user_roles (
--   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   workspace_user_id UUID NOT NULL,
--   workspace_role_id UUID NOT NULL,
--   created_at TIMESTAMP DEFAULT now(),
--   updated_at TIMESTAMP DEFAULT now(),
--   CONSTRAINT fk_workspace_user FOREIGN KEY (workspace_user_id) REFERENCES base.workspace_users (id) ON DELETE CASCADE ON UPDATE CASCADE,
--   CONSTRAINT fk_workspace_role FOREIGN KEY (workspace_role_id) REFERENCES base.workspace_roles (id) ON DELETE CASCADE ON UPDATE CASCADE,
-- );
-- ALTER TABLE
--   base.workspace_user_roles ENABLE ROW LEVEL SECURITY;
-- GRANT ALL ON base.workspace_user_roles TO authenticated;
-- workspace_user_roles table end
-- workspace_user_permissions table start
CREATE TABLE base.workspace_user_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL,
  user_id UUID NOT NULL,
  permissions text[] NOT NULL,
  CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES base.workspaces (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES base.users (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE UNIQUE INDEX idx_workspace_user_permissions ON base.workspace_user_permissions (workspace_id, user_id);
ALTER TABLE
  base.workspace_user_permissions ENABLE ROW LEVEL SECURITY;

GRANT ALL ON base.workspace_user_permissions TO authenticated;

-- workspace_user_permissions table end
-- workspace_resource_usage table start
-- CREATE TABLE base.workspace_resource_usage (
--   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   workspace_id UUID NOT NULL,
--   storage_used BIGINT DEFAULT 0,
--   api_calls_count BIGINT DEFAULT 0,
--   created_at TIMESTAMP DEFAULT now(),
--   updated_at TIMESTAMP DEFAULT now(),
--   CONSTRAINT fk_workspace FOREIGN KEY (workspace_id) REFERENCES base.workspaces (id) ON DELETE CASCADE ON UPDATE CASCADE
-- );

-- -- workspace_resource_usage table end
-- COMMENT ON COLUMN base.workspace_resource_usage.storage_used IS 'Storage usage in gbs/mbs';
-- ALTER TABLE
--   base.workspace_resource_usage ENABLE ROW LEVEL SECURITY;
-- GRANT SELECT ON base.workspace_resource_usage TO service_role;
