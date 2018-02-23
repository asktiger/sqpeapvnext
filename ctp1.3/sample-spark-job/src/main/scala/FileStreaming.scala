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
import scala.io.Source

// This is the base class for start a spark streaming session.
//
// TODO: We should work on converting the schema to correct SQL Server data type.
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

    // Read the data into a sql data frame as well
    // Persist the data to hdfs as a parquet file and create a schema in Hive
    // 
    val sqlDf = spark.read
      .format(inputFormat)
      .option("header", true)
      .schema(schema)
      .load(sourceDir)

    sqlDf.write.mode("overwrite").option("path", sourceDir + "/warehouse").saveAsTable(tableName)


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
}

// This object is used for starting spark streaming session using spark-submit
//
// The arguments to jar file are
// 1: server name - sql server to connect to read the table schema
// 2: port number
// 3: username
// 4: password
// 5: database name
// 6: table name
// 7: Source directory for streaming. This must be a full
//             URI - such as "file:///home/jarupat/aris/examples/inputdata/"
// 8: Input format. This can be "csv", "parquet", "json".
//
// Example of full command line.
// $> spark-submit --class "FileStreaming" mssql-spark-lib-assembly-1.0.jar <arguments>
//
object FileStreaming extends FileStreamingBase{
  def main(args: Array[String]): Unit = {
    if (args.length != 9) {
      System.err.println("Usage: FileStreaming <servername> <port> <username> <password> <databasename>" +
        " <tablename> <streaming source directory> <input file format> <enableCheckpoint>")
      System.exit(1)
    }

    val inputOptions = Map(
      "server" -> args(0),
      "port" -> args(1),
      "user" -> args(2),
      "password" -> args(3),
      "database" -> args(4),
      "enableCheckpoint" -> args(8))

    val tableName = args(5)
    val sourceDir = args(6)
    val inputFormat = args(7)

    val spark = SparkSession
      .builder
      .appName(s"FileStreaming_$tableName")
      .enableHiveSupport()
      .getOrCreate()

    StartStreaming(spark, inputOptions, tableName, sourceDir, inputFormat)
  }
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
//   "inputFormat" : "<input file data type - "csv", "parquet", "json">"
// }
//
// Example
// curl --request POST --header 'Content-type: application/json' "localhost:8090/jobs?appName=aris&classPath=FileStreamingJob"
// --data-binary '{"server":"localhost", "port":"1433", "user":"sa", "password":"password", "database":"mydb",
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
      .enableHiveSupport()
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

    if (inputFormat != "csv" &&
        inputFormat != "parquet" &&
        inputFormat != "json") {
      Bad(One(SingleProblem(s"Invalid inputFormat : $inputFormat.")))
    }
    else {
      val enableCheckpoint = Try(config.getString("checkpoint")).getOrElse(false)

      // Read secrets
      val username = config.getString("user")
      val secretPath = "/root/secrets/" + username.toLowerCase
      val bufferedFile = Source.fromFile(secretPath)
      val password = bufferedFile.getLines().next()
      bufferedFile.close()

      val inputMap = Map(
        "server" -> config.getString("server"),
        "port" -> config.getString("port"),
        "user" -> username,
        "password" -> password,
        "database" -> config.getString("database"),
        "table" -> config.getString("table"),
        "sourceDir" -> config.getString("parameter"),
        "inputFormat" -> inputFormat,
        "enableCheckpoint" -> enableCheckpoint.toString)

      Good(inputMap)
    }
  }
}
