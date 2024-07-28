# configuraciones

## Variables de entorno

Cree un archivo `.env`, haciendo una copia del archivo `env.template` y personalize las variables de entorno.

# Conexión a la base de datos

## PSQL-CLIENT

Puede interacturar con la base de datos utilice el contenedor `psql-client` definido en `docker-compose.yml`.
Ejecute el comando `docker-compose exec psql-client bash` para entrar al contenedor y despues ejecute el comando:

```bash
psql -h timescaledb -U $POSTGRES_USER -d $POSTGRES_DB
```