name := "mssql-spark-lib"

version := "1.0"

scalaVersion := "2.11.8"

val sparkVersion = "2.2.0"

// Default maven repository only have spark job server up to version 0.7.0.
// However, we need 0.8.0 to use with spark 2.2.0
//val jobserverVersion = "0.8.0-SNAPSHOT"

// Additional repository for job server. This repository also does not contains 0.8.0 version.
//
//resolvers += "Job Server Bintray" at "https://dl.bintray.com/spark-jobserver/maven"

libraryDependencies ++= Seq(
  // %% is used for project that was built with scala. This is because
  // sbt will append scala version to the artifactID
  // Details in http://www.scala-sbt.org/0.13/docs/Library-Dependencies.html
  //
  // "provided" means that the jar file will be excluded from the fat-jar
  // of this package.
  //
  "org.apache.spark" %% "spark-sql" % sparkVersion % "provided",
  "org.apache.spark" %% "spark-streaming" % sparkVersion % "provided",
  //"spark.jobserver" %% "job-server-api" % jobserverVersion % "provided",

  "com.microsoft.sqlserver" % "mssql-jdbc" % "latest.integration"
)
