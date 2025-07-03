A type-safe, fluent SQL query builder for Dart that provides a robust, expressive API for constructing complex SQL queries programmatically with full SQL injection protection.

Features ✨
Type-safe query building with compile-time checks

Fluent, chainable API inspired by modern ORMs

Comprehensive SELECT support:

JOINs (INNER, LEFT, RIGHT, FULL, CROSS)

Complex WHERE conditions with logical operators

GROUP BY with HAVING clauses

ORDER BY with multiple columns

LIMIT and OFFSET

SQL injection protection through automatic parameterization

Runtime validation for SQL identifiers and query structure

Aggregate functions (COUNT, SUM, AVG, MIN, MAX, GROUP_CONCAT)

Subquery support for EXISTS/NOT EXISTS conditions

Extensions for expressive syntax

Installation 📦
Add to your pubspec.yaml:

yaml
dependencies:
  sql_builder_plus: ^1.0.0
Usage 🚀
Basic SELECT
dart
final query = SQL.select([
  SQL.column('name'),
  SQL.column('age'),
])
.from(SQL.table('users'))
.where(SQL.column('age'), ComparisonOperator.greaterThan, 18)
.orderBy(SQL.column('name'), OrderDirection.asc)
.limit(10);

print(query.build());
// SELECT name, age FROM users WHERE age > @param_0 ORDER BY name ASC LIMIT 10
JOINs with Type Safety
dart
final users = SQL.table('users').as('u');
final orders = SQL.table('orders').as('o');

final query = SQL.select([
  users['name'].as('user_name'),
  SQL.count('id', table: orders).as('order_count'),
])
.from(users)
.innerJoin(orders, SQL.on(users['id'], orders['user_id']))
.groupBy([users['id']]);

print(query.build());
// SELECT u.name AS user_name, COUNT(o.id) AS order_count 
// FROM users AS u INNER JOIN orders AS o ON u.id = o.user_id 
// GROUP BY u.id
Complex WHERE Conditions
dart
final query = SQL.selectAll()
.from(SQL.table('products'))
.where(SQL.column('price'), ComparisonOperator.greaterThan, 100)
.andWhere(SQL.column('category'), ComparisonOperator.equals, 'Electronics')
.orGroup(Where.create()
  .where(SQL.column('stock'), ComparisonOperator.greaterThan, 0)
  .and(SQL.column('rating'), ComparisonOperator.greaterThanOrEqual, 4)
);

print(query.build());
// SELECT * FROM products 
// WHERE price > @param_0 AND category = @param_1 
// OR (stock > @param_2 AND rating >= @param_3)
Getting Parameters
dart
final result = query.buildResult();
print(result.sql);
print(result.parameters);

// Use with database clients:
// await client.query(result.sql, values: result.parameters.values.toList());
Why SQL Builder Plus? 💡
No magic strings: Column and table references are type-checked

Prevents SQL injection: All values are automatically parameterized

Readable syntax: Fluent API makes complex queries easy to construct

Validation: Catches invalid queries at runtime before execution

Lightweight: No heavy ORM dependencies, works with any database client

Roadmap 🛣️
INSERT, UPDATE, DELETE support

Batch query support

Database dialect customization

More extensive documentation and examples

Contributing 🤝
Contributions are welcome! Please open an issue or PR for any bugs, feature requests, or improvements.