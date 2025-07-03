SQL Builder Library for Dart
A robust and type-safe library for generating SQL SELECT queries in Dart, offering strong typing and protection against SQL injection.

Features
Type-Safe Query Construction: Build SQL queries using Dart objects and enums, reducing the risk of syntax errors and improving code readability.

SQL Injection Protection: Automatically parameterizes query values, safeguarding your application against common SQL injection vulnerabilities.

Comprehensive SELECT Support:

SELECT with specific columns or SELECT *

DISTINCT selections

FROM clause with single or multiple tables

Various JOIN types (INNER, LEFT, RIGHT, FULL, CROSS) with type-safe ON conditions

Complex WHERE and HAVING clauses with logical operators (AND, OR) and grouped conditions

Comparison operators (=, !=, >, >=, <, <=, LIKE, ILIKE, IN, BETWEEN, IS NULL, EXISTS)

GROUP BY with aggregate functions (COUNT, SUM, AVG, MIN, MAX, GROUP_CONCAT)

ORDER BY with ascending or descending directions

LIMIT and OFFSET for pagination

Fluent API: Chain methods for a more readable and concise query construction experience.

Extensible Design: Easily extendable to support additional SQL features or database-specific syntax.

Parameter Management: Provides access to generated SQL parameters for use with prepared statements.

Input Validation: Includes checks for valid identifiers (table and column names) and prevents the use of SQL keywords as identifiers.
