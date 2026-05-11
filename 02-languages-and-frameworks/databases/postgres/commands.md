Current Selected Database
```
SELECT current_database();
```

Structure of Table
```
SELECT * FROM country WHERE FALSE;
```

Show all tables in current database
```
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_type = 'BASE TABLE'
AND table_schema NOT IN ('pg_catalog', 'information_schema');
```