/*
 * Copyright(c) Microsoft Corporation All rights reserved.
 */

import java.io.IOException

import com.microsoft.mssqlspark.MsSQLForeachWriter
import com.microsoft.sqlserver.jdbc.SQLServerDataSource
import com.typesafe.config.Config
import org.apache.hadoop.fs.{FileSystem, Path}
import org.apache.spark.SparkContext
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.execution.datasources.jdbc.{DriverRegistry, JDBCOptions, JdbcUtils}
import org.scalactic._
import spark.jobserver.api.{JobEnvironment, SingleProblem, ValidationProblem, SparkJob => NewSparkJob}

import scala.collection.immutable.Map
import scala.collection.mutable
import scala.util.Try

// This is the base class for start a spark streaming session.
//
class FileStreamingBase {
  val checkpointRootLocation = "/checkpoint"

  def StartStreaming(spark: SparkSession, inputOptions: Map[String, String], tableName: String, sourceDir: String, inputFormat: String) = {
    val driverName = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
    DriverRegistry.register(driverName)

    val sqlNodeDataSource = new SQLServerDataSource()
    sqlNodeDataSource.setServerName(inputOptions("server"))
    sqlNodeDataSource.setPortNumber(inputOptions("port").toInt)
    sqlNodeDataSource.setUser(inputOptions("user"))
    sqlNodeDataSource.setPassword(inputOptions("password"))
    sqlNodeDataSource.setDatabaseName(inputOptions("database"))

    val jdbcOptions = new JDBCOptions(Map[String, String](
      JDBCOptions.JDBC_URL -> sqlNodeDataSource.getConnection().getMetaData.getURL,
      JDBCOptions.JDBC_TABLE_NAME -> tableName,
      JDBCOptions.JDBC_DRIVER_CLASS -> driverName))

    // Read a schema from table in SQL database
    //
    val schema = JdbcUtils.getSchemaOption(sqlNodeDataSource.getConnection(), jdbcOptions).get

    val lines = spark.readStream
      .format(inputFormat)
      .option("header", true)
      .schema(schema)
      .load(sourceDir)

    val fs = FileSystem.get(spark.sparkContext.hadoopConfiguration)
    val checkpointPath = new Path(checkpointRootLocation, tableName)
    var options = new mutable.HashMap[String, String]()
    if (inputOptions("enableCheckpoint") == "true") {
      // Create a checkpoint directory if it does not exist.
      // The checkpoint directory assumes to be the /checkpoint/tablename
      //
      try {
        fs.mkdirs(checkpointPath)
      } catch {
        case ioe : IOException => {
          println(ioe.getCause)
          println(ioe.getMessage)
        }
      }

      options += ("checkpointLocation" -> checkpointPath.toString)
    }
    else {
      // Delete directory if exist
      //
      try {
        fs.delete(checkpointPath, true)
      } catch {
        case ioe : IOException => {
          println(ioe.getCause)
          println(ioe.getMessage)
        }
      }
    }

    val query = lines.writeStream
      .outputMode("append")
      .options(options)
      .foreach(new MsSQLForeachWriter(tableName, inputOptions, schema))
      .start()

    query.awaitTermination()
  }

  /*
  This function can be override with your custom spark code.
 */
//  def StartStreaming(spark: SparkSession, inputOptions: Map[String, String], tableName: String, sourceDir: String, inputFormat: String) = {
//    // Insert your code here.
//  }
}

// This object is used for starting spark streaming session using spark job-server.
//
// THe job expects a JSON object with these key/value in the POST request data.
//
// { "server": "<sql server name>",
//   "port" : "<sql server port> ,
//   "user" : "<username>",
//   "password" : "<password>",
//   "database" : "<database to connect to>",
//   "table" : "<table to insert data>",
//   "sourceDir" : "<streaming source directory path>",
//   "inputFormat" : "<input file data type - "csv">"
// }
//
// Example
// curl --request POST --header 'Content-type: application/json' "localhost:8090/jobs?appName=aris&classPath=FileStreamingJob"
// --data-binary '{"server":"localhost", "port":"1433", "user":"user", "password":"password", "database":"mydb",
// "table":"mytable", "sourceDir":"/myfiles", "inputFormat":"csv"}'
//
object FileStreamingJob extends FileStreamingBase with NewSparkJob{
  type JobData = Map[String, String]
  type JobOutput = Any

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
      .appName("FileStreamingJob_"+ data("table"))
      .getOrCreate()

    StartStreaming(spark, data, data("table"), data("sourceDir"), data("inputFormat"))
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
    val inputFormat = config.getString("inputFormat").toLowerCase

    if (inputFormat != "csv" ) {
      Bad(One(SingleProblem(s"Invalid inputFormat : $inputFormat.")))
    }
    else {
      val enableCheckpoint = Try(config.getString("checkpoint")).getOrElse(false)

      val inputMap = Map(
        "server" -> config.getString("server"),
        "port" -> config.getString("port"),
        "user" -> config.getString("user"),
        "password" -> config.getString("password"),
        "database" -> config.getString("database"),
        "table" -> config.getString("table"),
        "sourceDir" -> config.getString("parameter"),
        "inputFormat" -> inputFormat,
        "enableCheckpoint" -> enableCheckpoint.toString)

      Good(inputMap)
    }
  }
}