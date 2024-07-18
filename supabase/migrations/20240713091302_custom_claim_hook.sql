create or replace function base.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
as $$
  declare
    claims jsonb;
    user_permissions text[];
  begin
    claims := event->'claims';

    -- select user workspace permissions
    select permissions into user_permissions from base.workspace_user_permissions where user_id = (event->>'user_id')::uuid and workspace_id = ((claims -> 'app_metadata')::jsonb ->> 'workspace_id')::uuid;

    if user_permissions is not null then
      claims := jsonb_set(claims, '{user_permissions}', to_jsonb(user_permissions));
    else
      claims := jsonb_set(claims, '{user_permissions}', 'null');
    end if;

    event := jsonb_set(event, '{claims}', claims);

    return event;
  end;
$$;

grant usage on schema base to supabase_auth_admin;

grant execute
  on function base.custom_access_token_hook
  to supabase_auth_admin;


grant select
  on table base.workspace_user_permissions
  to supabase_auth_admin;


revoke execute
  on function base.custom_access_token_hook
  from authenticated, anon, public;
