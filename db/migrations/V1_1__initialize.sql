create extension if not exists pgcrypto;
create schema if not exists api;

create role authenticator noinherit;

create role anon;
grant anon to authenticator;
