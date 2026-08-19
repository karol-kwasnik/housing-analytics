from pyspark.sql.functions import *
from pyspark.sql.types import *
from pyspark.sql.window import Window

for t in ["variable", "ingestion_config", "quality_attribute",
          "county_classification", "credit_parameter"]:
    (spark.read.parquet(f"Files/landing/ref/{t}")
          .write.mode("overwrite").option("overwriteSchema", "true")
          .saveAsTable(t))

schema = StructType([
    StructField("results", ArrayType(StructType([
        StructField("id", StringType()),
        StructField("name", StringType()),
        StructField("values", ArrayType(StructType([
            StructField("year", StringType()),
            StructField("val", DoubleType()),
            StructField("attrId", IntegerType())
        ])))
    ])))
])

raw_files = (spark.read
    .schema(schema)
    .option("basePath", "Files/landing/bdl/")
    .json("Files/landing/bdl/ingestion_date=*/variable_id=*/data.json"))

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
