/*
 * Copyright(c) Microsoft Corporation All rights reserved.
 */

package com.microsoft.mssqlspark

import scala.collection.Map
import java.sql.{Connection, PreparedStatement}

import com.microsoft.sqlserver.jdbc.SQLServerDataSource
import org.apache.spark.sql.execution.datasources.jdbc.JdbcUtils.getCommonJDBCType
import org.apache.spark.sql.execution.datasources.jdbc.DriverRegistry
import org.apache.spark.sql.jdbc.{JdbcDialects}
import org.apache.spark.sql.types._
import org.apache.spark.sql.{ForeachWriter, Row}

// Class that implements ForeachWriter interface to do a special processing of output streaming data.
// In this case, inserting streaming data into SQL Server.
//
// This class creates a connection to SQL server local to the node that spark executor is executing on.
// It creates a transaction for all the rows that this executor processes. The insert statements are
// sent as a batch of 1000 statements. At the end of the processing, we will commit the transaction
// and close the connection.
//
// The interface that we need to implement are open(), process() and close()
//
class MsSQLForeachWriter (tablename: String,
                          connectionProperties: Map[String, String],
                          schema: StructType ) extends ForeachWriter[Row] {
  var count: Int = 0;
  var statement: PreparedStatement = _;
  var conn: Connection = _;

  val driverName = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
  DriverRegistry.register(driverName)

  JdbcDialects.registerDialect(SqlServerDialect)

  var localNodeDataSource = new SQLServerDataSource()
  localNodeDataSource.setServerName("localhost")
  localNodeDataSource.setPortNumber(1433)
  localNodeDataSource.setDatabaseName(connectionProperties("database"))

  override def open(partitionId: Long, version: Long): Boolean = {
    // Create a connection to local table
    //
    conn = localNodeDataSource.getConnection(connectionProperties("user"), connectionProperties("password"))

    // Do not auto-commit each statement. Instead, we will commit at the end to reduce the transaction overhead.
    //
    conn.setAutoCommit(false)

    val insertStatement: String = CreateInsertStatement(tablename)

    statement = conn.prepareStatement(insertStatement)

    return true
  }

  // Create a prepare insert statement from a schema with '?' parameter marker.
  //
  private def CreateInsertStatement(tablename: String) : String = {
    // Generate insert statement. The number of ? will be equal to the number of columns
    // in the schema.
    //
    val insertStatement = new StringBuilder
    insertStatement.append(s"INSERT INTO [$tablename] values (")

    for (i <- 0 until schema.length) {
      if (i == 0) {
        insertStatement.append("?")
      }
      else {
        insertStatement.append(" ,?")
      }
    }
    insertStatement.append(")")
    return insertStatement.toString()
  }

  override def process(value: Row): Unit = {
    // For each value in a row, convert Spark datatype to the correct JDBC data type for insert.
    //
    // JDBC statement set* (setString, setInt, etc) use 1 base offset. However, the array is 0 base offset.
    //
    try {
      val dialect = JdbcDialects.get("jdbc:sqlserver")
      val columnType = value.schema.fields
      for (i <- 0 until value.length) {
        val dataType = columnType(i).dataType
        val sqlType = dialect.getJDBCType(dataType).orElse(getCommonJDBCType(columnType(i).dataType)).getOrElse(
          throw new IllegalArgumentException(s"Can't get JDBC type for ${dataType.simpleString}"))

        if (value.isNullAt(i)) {
          statement.setNull(i + 1, sqlType.jdbcNullType)
        }
        else {
          columnType(i).dataType match {
            case IntegerType => statement.setInt(i + 1, value.getInt(i))
            case LongType => statement.setLong(i + 1, value.getLong(i))
            case DoubleType => statement.setDouble(i + 1, value.getDouble(i))
            case FloatType => statement.setFloat(i + 1, value.getFloat(i))
            case ShortType => statement.setShort(i + 1, value.getShort(i))
            case ByteType => statement.setByte(i + 1, value.getByte(i))
            case t: DecimalType => statement.setBigDecimal(i + 1, value.getDecimal(i))
            case StringType => statement.setString(i + 1, value.getString(i))
            case BooleanType => statement.setBoolean(i + 1, value.getBoolean(i))
            case BinaryType => statement.setBytes(i + 1, value.getAs[Array[Byte]](i))
            case TimestampType => statement.setTimestamp(i + 1, value.getTimestamp(i))
            case DateType => statement.setDate(i + 1, value.getDate(i))
            case _ => throw new IllegalArgumentException(s"Can't translate non-null value for field $i")
          }
        }
      }
    } catch {
      case e : IllegalArgumentException => {
        println(e.getMessage + "\n" + value.toString())
      }
    }

    count += 1

    statement.addBatch()

    // Batch 1000 insert statements as a batch before sending them to SQL for execution.
    //
    if (count % 1000 == 0)
    {
      statement.executeBatch()
    }
  }

  override def close(errorOrNull: Throwable): Unit = {
    // Execute the rest of the insert statement
    //
    statement.executeBatch()
    statement.close()

    // Commit the transaction.
    //
    conn.commit()
    conn.close()
  }
}
