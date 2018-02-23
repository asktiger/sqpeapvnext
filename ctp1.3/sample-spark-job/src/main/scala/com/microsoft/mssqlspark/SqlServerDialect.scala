/*
 * Copyright(c) Microsoft Corporation All rights reserved.
 */

package com.microsoft.mssqlspark

import org.apache.spark.sql.jdbc.{JdbcDialect, JdbcType}
import org.apache.spark.sql.types._

// Implemented JdbcDialect to expand Spark data type conversion to support SQL Server data type.
// Spark has already provided MsSqlServerDialect as a default conversion to SQL Server data type.
// We are overriding some data type in this implementation.
//
object SqlServerDialect extends JdbcDialect {
  override def canHandle(url: String): Boolean = url.startsWith("jdbc:sqlserver")

  // Use default conversion.
  //
  override def getCatalystType(
      sqlType: Int, typeName: String, size: Int, md: MetadataBuilder): Option[DataType] = None

  // This function convert Spark data type to SQL Server data type. It overrides
  // default conversion provided by Spark [See Spark JdbcUtils]. The complex datatype
  // such as ArrayType and MapType are treated as String and converted to NVARCHAR(MAX).
  //
  override def getJDBCType(dt: DataType): Option[JdbcType] = dt match {
    case ByteType => Some(JdbcType("TINYINT", java.sql.Types.TINYINT))
    case TimestampType => Some(JdbcType("DATETIME2", java.sql.Types.TIMESTAMP))
    case DoubleType => Some(JdbcType("FLOAT", java.sql.Types.DOUBLE))
    case BinaryType => Some(JdbcType("VARBINARY(MAX)", java.sql.Types.VARBINARY))
    case _ => None
  }

  override def isCascadingTruncateTable(): Option[Boolean] = Some(false)
}
