-- accessor functions
create schema if not exists fn;
create or replace function fn.req_var(v text) returns text as $$
declare
  result text;
begin
  begin
    select current_setting(v) into result;
    exception
    when undefined_object then
      return null;
  end;

  return result;
end;
$$ stable language plpgsql;



create or replace function fn.claim(v text) returns text as $$
declare
  result text;
begin
  return fn.req_var('request.jwt.claim.' || v);
end;
$$ stable language plpgsql;



CREATE OR REPLACE FUNCTION fn.pre_request() RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_user VARCHAR;
BEGIN
  SELECT current_user into v_user;
  raise WARNING '1 as %', v_user;

  select fn.claim('email') into v_user;
  raise WARNING '2 as %', v_user;

  SELECT fn.req_var('request.jwt.claim.email') into v_user;
  raise WARNING '3 as %', v_user;



--   v_user := fn.req_var('request.jwt.claim.email');
--   raise WARNING 'prerequest %', v_user;

  --   IF v_user = 'evil_user' THEN
  --     RAISE EXCEPTION 'No, you are evil'
  --     USING HINT = 'Stop being so evil and maybe you can log in';
  --   END IF;

END
$$;
