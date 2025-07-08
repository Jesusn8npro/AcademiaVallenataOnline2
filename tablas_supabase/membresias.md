[
  {
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()"
  },
  {
    "column_name": "nombre",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "column_name": "descripcion",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "column_name": "precio_mensual",
    "data_type": "numeric",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "column_name": "precio_anual",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "column_name": "color_hex",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'#6366f1'::text"
  },
  {
    "column_name": "icono",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": "'🎵'::text"
  },
  {
    "column_name": "orden",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "column_name": "activa",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "true"
  },
  {
    "column_name": "destacada",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false"
  },
  {
    "column_name": "beneficios",
    "data_type": "jsonb",
    "is_nullable": "NO",
    "column_default": "'[]'::jsonb"
  },
  {
    "column_name": "permisos",
    "data_type": "jsonb",
    "is_nullable": "NO",
    "column_default": "'{}'::jsonb"
  },
  {
    "column_name": "tagline",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "column_name": "descuento_anual",
    "data_type": "integer",
    "is_nullable": "YES",
    "column_default": "20"
  },
  {
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()"
  },
  {
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()"
  }
]