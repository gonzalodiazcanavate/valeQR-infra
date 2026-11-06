#!/bin/sh
# Roles de BD: propietario (migraciones) y login de la aplicación (sin privilegios propios).
# Se ejecuta solo en la primera inicialización del volumen de PostgreSQL.
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
  -v owner_pw="$AUTOQR_OWNER_PASSWORD" -v app_pw="$AUTOQR_APP_PASSWORD" <<'SQL'
CREATE ROLE autoqr_owner LOGIN PASSWORD :'owner_pw';
CREATE ROLE autoqr_app NOLOGIN;
-- NOINHERIT: el login no puede tocar tablas hasta hacer SET ROLE autoqr_app (lo hace withTenant, sujeto a RLS).
CREATE ROLE autoqr_app_login LOGIN NOINHERIT PASSWORD :'app_pw';
GRANT autoqr_app TO autoqr_app_login;

CREATE DATABASE autoqr OWNER autoqr_owner;
REVOKE CONNECT ON DATABASE autoqr FROM PUBLIC;
GRANT CONNECT ON DATABASE autoqr TO autoqr_owner, autoqr_app_login;
SQL
