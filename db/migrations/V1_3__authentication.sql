-- authentication
create schema if not exists basic_auth;
create table if not exists
  basic_auth.users (
  email    text primary key check ( email ~* '^.+@.+\..+$' ),
  pass     text not null check (length(pass) < 512),
  role     name not null check (length(role) < 512)
);

-- ensure roles are valid
create or replace function
  basic_auth.check_role_exists() returns trigger
language plpgsql
as $$
begin
  if not exists (select 1 from pg_catalog.pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$;

drop trigger if exists ensure_user_role_exists on basic_auth.users;
create constraint trigger ensure_user_role_exists
after insert or update on basic_auth.users
for each row
execute procedure basic_auth.check_role_exists();


-- encrypt the password using bcrypt
create or replace function
  basic_auth.encrypt_pass() returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' or new.pass <> old.pass then
    new.pass = crypt(new.pass, gen_salt('bf'));
  end if;
  return new;
end
$$;
drop trigger if exists encrypt_pass on basic_auth.users;
create trigger encrypt_pass
before insert or update on basic_auth.users
for each row
execute procedure basic_auth.encrypt_pass();

-- helper function
create or replace function
  basic_auth.user_role(email text, pass text) returns name
language plpgsql
as $$
begin
  return (
    select role from basic_auth.users
    where users.email = user_role.email
          and users.pass = crypt(user_role.pass, users.pass)
  );
end;
$$;

CREATE TYPE basic_auth.jwt_token AS (
  token text
);


-- login function
create or replace function
  api.login(email text, pass text) returns basic_auth.jwt_token
language plpgsql
as $$
declare
  _role name;
  result basic_auth.jwt_token;
begin
  -- check email and password
  select basic_auth.user_role(email, pass) into _role;
  if _role is null then
    raise invalid_password using message = 'invalid user or password';
  end if;

  select jwt.sign(
             row_to_json(r), 'mysecret'
         ) as token
  from (
         select _role as role, login.email as email,
                extract(epoch from now())::integer + 60*60 as exp
       ) r
  into result;
  return result;
end;
$$;
