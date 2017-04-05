grant usage on schema fn to authenticator;
grant usage on schema api, basic_auth,jwt,fn to anon;
grant select on table pg_authid, basic_auth.users to anon;
