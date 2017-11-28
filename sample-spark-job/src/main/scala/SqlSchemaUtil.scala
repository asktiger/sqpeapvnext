/*
 * Copyright(c) Microsoft Corporation All rights reserved.
 */

import java.io.BufferedOutputStream

import com.microsoft.mssqlspark.SqlServerDialect
import org.apache.hadoop.fs.{FileSystem, Path}
import org.apache.spark.SparkContext
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.execution.datasources.jdbc.JdbcUtils.schemaString
import org.scalactic._
import spark.jobserver.api.{SparkJob => NewSparkJob, _}
import com.typesafe.config.{Config, ConfigException}
import org.apache.spark.sql.jdbc.JdbcDialects

import scala.collection.mutable

// This is the base class for inferring schema from a csv file.
// The output string of this function will be used in create table statement.
// For example,
// "processed" DATETIME2(3) , "id" INTEGER , "cycle" INTEGER
//
class SqlSchemaUtilBase {
  JdbcDialects.registerDialect(SqlServerDialect)

  def getSchemaString(spark: SparkSession,
                      inputFilePath: String,
                      inputFormat: String,
                      overrideType: mutable.Map[String,String]) : String = {
    val df = spark.read
      .format(inputFormat)
      .option("header", true)
      .option("inferSchema", true)
      .load(inputFilePath)

    var strSchema = schemaString(df, "jdbc:sqlserver")

    for((k,v) <- overrideType) {
      strSchema = strSchema.replaceAll(k, v)
    }

    return strSchema
  }

  /*
    Instead of inferring schema from a sample file. If we want to create a specific schema in an external
    table, we can hard coded the schema using this string.
   */
//  def getSchemaString(spark: SparkSession,
//                      inputFilePath: String,
//                      inputFormat: String,
//                      overrideType: mutable.Map[String,String]) : String = {
//    return "c1 INT, c2 DECIMAL(10,2), c3 DATETIME2";
//  }
}

// This object is used for executing SqlSchemaUtilBase::getSchemaString from a spark job-server.
//
// The job expected a json input from the POST data content. The JSON must have object with inputFile key.
// The value to the input file is the path to the input which the job should read to inferring schema.
//
// For example:
// curl "localhost:8090/jobs?appName-mssql&classpath=SqlSchemaUtilJob"
// -- request POST --header 'Content-type: application/json'
// --data-binary '{"inputFile":"/airlinedata/inputfile.csv"}'
//
object SqlSchemaUtilJob extends SqlSchemaUtilBase with NewSparkJob {
  type JobData = Config
  type JobOutput = String

  /**
    * This is the entry point for a Spark Job Server to execute Spark jobs.
    * This function should create or reuse RDDs and return the result at the end, which the
    * Job Server will cache or display.
    *
    * @param sc      a SparkContext or similar for the job.  May be reused across jobs.
    * @param runtime the JobEnvironment containing run time information pertaining to the job and context.
    * @param data    the JobData returned by the validate method
    * @return the job result
    */
  def runJob(sc: SparkContext, runtime: JobEnvironment, data: JobData): JobOutput = {
    val spark = SparkSession
      .builder
      .appName("SqlSchemaUtil")
      .getOrCreate()

    var overrideType = mutable.Map[String, String]()
    var inputFormat = "csv"

    try {
      val configList = data.getConfigList("overrideType")

      val it = configList.iterator()
      while (it.hasNext) {
        val config = it.next()
        overrideType += config.getString("key") -> config.getString("value")
      }
    } catch {
      case e : ConfigException.Missing => {
        println(e.getMessage)
      }
    }

    // If the user does not specify input format, then we assume it to be a csv.
    //
    try {
      inputFormat = data.getString("inputFormat")
    } catch {
      case e : ConfigException.Missing => {
        println(e.getMessage)
      }
    }

    return getSchemaString(spark,
      data.getString("inputFile"),
      inputFormat,
      overrideType)
  }

  /**
    * This method is called by the job server to allow jobs to validate their input and reject
    * invalid job requests.  If SparkJobInvalid is returned, then the job server returns 400
    * to the user.
    * NOTE: this method should return very quickly.  If it responds slowly then the job server may time out
    * trying to start this job.
    *
    * @param sc      a SparkContext or similar for the job.  May be reused across jobs.
    * @param runtime the JobEnvironment containing run time information pertaining to the job and context.
    * @param config  the Typesafe Config object passed into the job request
    * @return either JobData, which is parsed from config, or a list of validation issues.
    */
  def validate(sc: SparkContext, runtime: JobEnvironment, config: Config): JobData Or Every[ValidationProblem] = {
    Good(config)
  }
}