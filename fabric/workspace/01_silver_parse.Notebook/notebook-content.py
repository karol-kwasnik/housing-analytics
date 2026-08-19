# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "dd05336a-9a71-485a-a916-ce01c0506150",
# META       "default_lakehouse_name": "lh_bronze",
# META       "default_lakehouse_workspace_id": "7be0790d-3450-465a-86e3-14a0e2e63029",
# META       "known_lakehouses": [
# META         {
# META           "id": "dca1d089-6df7-44ba-b234-f34e109adc8b"
# META         },
# META         {
# META           "id": "dd05336a-9a71-485a-a916-ce01c0506150"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

for t in ["variable", "ingestion_config", "quality_attribute",
          "county_classification", "credit_parameter"]:
    (spark.read.parquet(f"Files/landing/ref/{t}")
          .write.mode("overwrite").option("overwriteSchema", "true")
          .saveAsTable(t))

display(spark.table("quality_attribute"))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql.window import Window

parsed = (raw_files
    .select("variable_id", "ingestion_date", explode("results").alias("unit"))
    .select("variable_id", "ingestion_date",
            col("unit.id").alias("teryt_code"),
            col("unit.name").alias("unit_name"),
            explode("unit.values").alias("v"))
    .select("variable_id", "ingestion_date", "teryt_code", "unit_name",
            col("v.year").cast("int").alias("year"),
            col("v.val").alias("val"),
            col("v.attrId").alias("attribute_id")))

attributes = spark.table("quality_attribute").select("attribute_id", "is_value", "symbol")

unknown = parsed.join(attributes, "attribute_id", "left_anti").select("attribute_id").distinct()
if unknown.count() > 0:
    raise ValueError(f"Unknown attribute_id: {[r.attribute_id for r in unknown.collect()]}")

config = spark.table("ingestion_config").select("variable_id", "unit_level")

clean = (parsed
    .join(attributes, "attribute_id", "left")
    .join(config, "variable_id", "left")
    .withColumn("value", when(col("is_value"), col("val")))
    .withColumn("quality_flag",
                when(trim(col("symbol")) == "", lit(None)).otherwise(trim(col("symbol"))))
    .withColumn("voivodeship_code", substring("teryt_code", 3, 2))
    .withColumn("subregion_code", substring("teryt_code", 1, 7))
    .withColumn("level_name", when(col("unit_level") == 4, "subregion")
                              .when(col("unit_level") == 5, "county")
                              .otherwise("other")))

w = Window.partitionBy("teryt_code", "year", "variable_id").orderBy(desc("ingestion_date"))
deduped = clean.withColumn("rn", row_number().over(w)).filter(col("rn") == 1).drop("rn")

(deduped
    .select("variable_id", "teryt_code", "unit_name", "year", "value", "val",
            "quality_flag", "attribute_id", "unit_level", "level_name",
            "voivodeship_code", "subregion_code", "ingestion_date")
    .write.mode("overwrite").option("overwriteSchema", "true")
    .saveAsTable("lh_silver.fact_bdl"))

print("rows:", spark.table("lh_silver.fact_bdl").count())

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

display(spark.sql("""
    SELECT year, val, value, quality_flag, attribute_id
    FROM lh_silver.fact_bdl
    WHERE teryt_code = '012414967000' AND variable_id = 64428
    ORDER BY year
"""))

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
