[
  {
    "column_name": "creado_en",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()"
  },
  {
    "column_name": "actualizado_en",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "now()"
  },
  {
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": "gen_random_uuid()"
  },
  {
    "column_name": "contenido",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "column_name": "imagen_url",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "column_name": "estado",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": "'borrador'::text"
  },
  {
    "column_name": "slug",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "column_name": "titulo",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "column_name": "resumen",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  }
]