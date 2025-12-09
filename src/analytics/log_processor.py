import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv,)
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args, args)

# 1. Ler dados brutos (JSON) do S3 (Data Lake Raw)
datasource0 = glueContext.create_dynamic_frame.from_catalog(
    database = "soundwave_analytics_db", 
    table_name = "raw_app_events"
)

# 2. Transformação: Mapear campos e converter tipos
applymapping1 = ApplyMapping.apply(
    frame = datasource0, 
    mappings = [
        ("user_id", "string", "user_id", "string"),
        ("track_id", "string", "track_id", "string"),
        ("event_type", "string", "event_type", "string"),
        ("timestamp", "string", "event_time", "timestamp")
    ]
)

# 3. Escrita Otimizada (Parquet) no S3 (Data Lake Processed)
datasink2 = glueContext.write_dynamic_frame.from_options(
    frame = applymapping1, 
    connection_type = "s3", 
    connection_options = {"path": "s3://soundwave-analytics-prod/processed/events/"}, 
    format = "parquet"
)

job.commit()