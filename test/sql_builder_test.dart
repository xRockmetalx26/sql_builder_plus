import 'package:sql_builder_plus/sql_builder_plus.dart';
import 'package:test/test.dart';

void main() {
  group('SqlBuilder Basic Select', () {
    test('1. Should build a simple SELECT * from a table', () {
      final query = SQL.selectAll().from(SQL.table('users')).build();
      expect(query, 'SELECT * FROM users');
    });

    test('2. Should build a simple SELECT with specific columns', () {
      final query = SQL
          .select([SQL.column('id'), SQL.column('name')])
          .from(SQL.table('products'))
          .build();
      expect(query, 'SELECT id, name FROM products');
    });

    test('3. Should build SELECT with a table alias', () {
      final users = SQL.table('users').as('u');
      final query = SQL
          .select([users.col('id'), users.col('name').as('user_name')])
          .from(users)
          .build();
      expect(query, 'SELECT u.id, u.name AS user_name FROM users AS u');
    });

    test('4. Should build a SELECT DISTINCT query', () {
      final query = SQL
          .select([SQL.column('category')])
          .distinct()
          .from(SQL.table('products'))
          .build();
      expect(query, 'SELECT DISTINCT category FROM products');
    });

    test(
      '5. Should throw SqlBuilderException if SELECT has no columns and not selectAll',
      () {
        expect(
          () => SqlBuilder().select([]).from(SQL.table('users')).build(),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );
  });

  group('SqlBuilder FROM Clause', () {
    test('6. Should build query with multiple FROM tables', () {
      final query = SQL
          .select([SQL.column('col1'), SQL.column('col2')])
          .fromTables([SQL.table('table1'), SQL.table('table2')])
          .build();
      expect(query, 'SELECT col1, col2 FROM table1, table2');
    });

    test('7. Should throw SqlBuilderException if FROM has no tables', () {
      expect(
        () => SqlBuilder().select([SQL.column('id')]).fromTables([]).build(),
        throwsA(isA<SqlBuilderException>()),
      );
    });

    test(
      '8. Should throw SqlBuilderException if query has no FROM or JOIN clause',
      () {
        expect(
          () => SQL.select([SQL.column('id')]).build(),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );
  });

  group('SqlBuilder JOIN Clauses', () {
    final users = SQL.table('users');
    final orders = SQL.table('orders');
    final products = SQL.table('products');

    test('9. Should build an INNER JOIN query', () {
      final query = SQL
          .select([users.col('id'), orders.col('order_id')])
          .from(users)
          .innerJoin(orders, SQL.on(users.col('id'), orders.col('user_id')))
          .build();
      expect(
        query,
        'SELECT users.id, orders.order_id FROM users INNER JOIN orders ON users.id = orders.user_id',
      );
    });

    test('10. Should build a LEFT JOIN query', () {
      final query = SQL
          .select([users.col('name'), orders.col('amount')])
          .from(users)
          .leftJoin(orders, SQL.on(users.col('id'), orders.col('user_id')))
          .build();
      expect(
        query,
        'SELECT users.name, orders.amount FROM users LEFT JOIN orders ON users.id = orders.user_id',
      );
    });

    test('11. Should build a RIGHT JOIN query', () {
      final query = SQL
          .select([users.col('name'), orders.col('amount')])
          .from(users)
          .rightJoin(orders, SQL.on(users.col('id'), orders.col('user_id')))
          .build();
      expect(
        query,
        'SELECT users.name, orders.amount FROM users RIGHT JOIN orders ON users.id = orders.user_id',
      );
    });

    test('12. Should build a FULL OUTER JOIN query', () {
      final query = SQL
          .select([users.col('name'), orders.col('amount')])
          .from(users)
          .fullJoin(orders, SQL.on(users.col('id'), orders.col('user_id')))
          .build();
      expect(
        query,
        'SELECT users.name, orders.amount FROM users FULL OUTER JOIN orders ON users.id = orders.user_id',
      );
    });

    test('13. Should build a CROSS JOIN query', () {
      final query = SQL
          .select([users.col('name'), products.col('product_name')])
          .from(users)
          .crossJoin(products)
          .build();
      expect(
        query,
        'SELECT users.name, products.product_name FROM users CROSS JOIN products ON 1 = 1',
      );
    });

    test('14. Should build a JOIN with table aliases', () {
      final u = SQL.table('users').as('u');
      final o = SQL.table('orders').as('o');
      final query = SQL
          .select([u.col('id'), o.col('order_id')])
          .from(u)
          .innerJoin(o, SQL.on(u.col('id'), o.col('user_id')))
          .build();
      expect(
        query,
        'SELECT u.id, o.order_id FROM users AS u INNER JOIN orders AS o ON u.id = o.user_id',
      );
    });

    test('15. Should build a JOIN with a custom operator', () {
      final query = SQL
          .select([users.col('id'), orders.col('order_id')])
          .from(users)
          .innerJoin(
            orders,
            SQL.onWith(
              users.col('id'),
              orders.col('user_id'),
              ComparisonOperator.greaterThan,
            ),
          )
          .build();
      expect(
        query,
        'SELECT users.id, orders.order_id FROM users INNER JOIN orders ON users.id > orders.user_id',
      );
    });
  });

  group('SqlBuilder WHERE Clauses', () {
    final users = SQL.table('users');

    test('16. Should build a WHERE clause with equals operator', () {
      final result = SQL
          .selectAll()
          .from(users)
          .where(users.col('id'), ComparisonOperator.equals, 1)
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.id = @param_0');
      expect(result.parameters['param_0'], 1);
    });

    test('17. Should build a WHERE clause with not equals operator', () {
      final result = SQL
          .selectAll()
          .from(users)
          .where(users.col('status'), ComparisonOperator.notEquals, 'active')
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.status != @param_0');
      expect(result.parameters['param_0'], 'active');
    });

    test('18. Should build a WHERE clause with greater than operator', () {
      final result = SQL
          .selectAll()
          .from(users)
          .where(users.col('age'), ComparisonOperator.greaterThan, 18)
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.age > @param_0');
      expect(result.parameters['param_0'], 18);
    });

    test(
      '19. Should build a WHERE clause with less than or equal operator',
      () {
        final result = SQL
            .selectAll()
            .from(users)
            .where(
              users.col('price'),
              ComparisonOperator.lessThanOrEqual,
              99.99,
            )
            .buildResult();
        expect(result.sql, 'SELECT * FROM users WHERE users.price <= @param_0');
        expect(result.parameters['param_0'], 99.99);
      },
    );

    test('20. Should build a WHERE clause with LIKE operator', () {
      final result = SQL
          .selectAll()
          .from(users)
          .where(users.col('name'), ComparisonOperator.like, 'John%')
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.name LIKE @param_0');
      expect(result.parameters['param_0'], 'John%');
    });

    test('21. Should build a WHERE clause with IS NULL operator', () {
      final result = SQL
          .selectAll()
          .from(users)
          .where(users.col('email'), ComparisonOperator.isNull, null)
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.email IS NULL');
    });

    test('22. Should build a WHERE clause with IN LIST operator', () {
      final result = SQL.selectAll().from(users).where(
        users.col('id'),
        ComparisonOperator.inList,
        [1, 2, 3],
      ).buildResult();
      expect(
        result.sql,
        'SELECT * FROM users WHERE users.id IN (@param_0, @param_1, @param_2)',
      );
      expect(result.parameters['param_0'], 1);
      expect(result.parameters['param_1'], 2);
      expect(result.parameters['param_2'], 3);
    });

    test('23. Should throw SqlBuilderException for empty IN list', () {
      expect(
        () => SQL
            .selectAll()
            .from(users)
            .where(users.col('id'), ComparisonOperator.inList, [])
            .build(),
        throwsA(isA<SqlBuilderException>()),
      );
    });

    test('24. Should build a WHERE clause with BETWEEN operator', () {
      final result = SQL.selectAll().from(users).where(
        users.col('age'),
        ComparisonOperator.between,
        [20, 30],
      ).buildResult();
      expect(
        result.sql,
        'SELECT * FROM users WHERE users.age BETWEEN @param_0 AND @param_1',
      );
      expect(result.parameters['param_0'], 20);
      expect(result.parameters['param_1'], 30);
    });

    test(
      '25. Should throw SqlBuilderException for BETWEEN with incorrect list size',
      () {
        expect(
          () => SQL.selectAll().from(users).where(
            users.col('age'),
            ComparisonOperator.between,
            [20],
          ).build(),
          throwsA(isA<SqlBuilderException>()),
        );
        expect(
          () => SQL.selectAll().from(users).where(
            users.col('age'),
            ComparisonOperator.between,
            [20, 30, 40],
          ).build(),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );

    test('26. Should build WHERE with AND condition', () {
      final result = SQL
          .selectAll()
          .from(users)
          .where(users.col('status'), ComparisonOperator.equals, 'active')
          .andWhere(users.col('age'), ComparisonOperator.greaterThan, 25)
          .buildResult();
      expect(
        result.sql,
        'SELECT * FROM users WHERE users.status = @param_0 AND users.age > @param_1',
      );
      expect(result.parameters['param_0'], 'active');
      expect(result.parameters['param_1'], 25);
    });

    test('27. Should build WHERE with OR condition', () {
      final result = SQL
          .selectAll()
          .from(users)
          .where(users.col('status'), ComparisonOperator.equals, 'inactive')
          .orWhere(users.col('role'), ComparisonOperator.equals, 'admin')
          .buildResult();
      expect(
        result.sql,
        'SELECT * FROM users WHERE users.status = @param_0 OR users.role = @param_1',
      );
      expect(result.parameters['param_0'], 'inactive');
      expect(result.parameters['param_1'], 'admin');
    });

    test('70. ColumnReference.gt should create correct condition', () {
      final condition = users.col('age').gt(25);
      final params = <String, SqlParameter>{};
      final sql = condition.toSql(params);
      expect(sql, 'users.age > @param_0');
      expect(params['param_0']!.value, 25);
    });

    test('29. Should build a WHERE EXISTS subquery', () {
      final orders = SQL.table('orders');
      final subquery = SQL
          .select([orders.col('id')])
          .from(orders)
          .where(
            orders.col('user_id'),
            ComparisonOperator.equals,
            users.col('id'),
          );

      // CORRECTED: Replaced the invalid `where(SQL.column('1'), ...)` with
      // a dedicated `Where.exists` condition, making the API usage
      // consistent with other `Where` convenience methods.
      final result = SQL
          .selectAll()
          .from(users)
          .whereGroup(Where.exists(subquery))
          .buildResult();

      expect(
        result.sql,
        'SELECT * FROM users WHERE EXISTS (SELECT orders.id FROM orders WHERE orders.user_id = users.id)',
      );
      expect(result.parameters, isEmpty);
    });

    test('30. Should build a WHERE NOT EXISTS subquery', () {
      final orders = SQL.table('orders');
      final subquery = SQL
          .select([orders.col('id')])
          .from(orders)
          .where(
            orders.col('user_id'),
            ComparisonOperator.equals,
            users.col('id'),
          );

      // CORRECTED: Applied the same logic for NOT EXISTS.
      final result = SQL
          .selectAll()
          .from(users)
          .whereGroup(Where.notExists(subquery))
          .buildResult();

      expect(
        result.sql,
        'SELECT * FROM users WHERE NOT EXISTS (SELECT orders.id FROM orders WHERE orders.user_id = users.id)',
      );
      expect(result.parameters, isEmpty);
    });
  });

  group('SqlBuilder GROUP BY and HAVING Clauses', () {
    final orders = SQL.table('orders');

    test('31. Should build a GROUP BY clause', () {
      final query = SQL
          .select([orders.col('user_id'), SQL.countAll().as('order_count')])
          .from(orders)
          .groupBy([orders.col('user_id')])
          .build();
      expect(
        query,
        'SELECT orders.user_id, COUNT(*) AS order_count FROM orders GROUP BY orders.user_id',
      );
    });

    test('32. Should build a GROUP BY with multiple columns', () {
      final query = SQL
          .select([
            orders.col('user_id'),
            orders.col('product_id'),
            SQL.sum('amount').as('total_amount'),
          ])
          .from(orders)
          .groupBy([orders.col('user_id'), orders.col('product_id')])
          .build();
      expect(
        query,
        'SELECT orders.user_id, orders.product_id, SUM(amount) AS total_amount FROM orders GROUP BY orders.user_id, orders.product_id',
      );
    });

    test('33. Should build a HAVING clause', () {
      final query = SQL
          .select([orders.col('user_id'), SQL.countAll().as('order_count')])
          .from(orders)
          .groupBy([orders.col('user_id')])
          .having(SQL.countAll(), ComparisonOperator.greaterThan, 5)
          .buildResult();
      expect(
        query.sql,
        'SELECT orders.user_id, COUNT(*) AS order_count FROM orders GROUP BY orders.user_id HAVING COUNT(*) > @param_0',
      );
      expect(query.parameters['param_0'], 5);
    });

    test('34. Should build a complex HAVING clause with AND and OR', () {
      final query = SQL
          .select([orders.col('user_id'), SQL.sum('amount').as('total_spent')])
          .from(orders)
          .groupBy([orders.col('user_id')])
          .having(SQL.sum('amount'), ComparisonOperator.greaterThan, 100)
          .andHaving(SQL.countAll(), ComparisonOperator.lessThan, 10)
          .buildResult();
      expect(
        query.sql,
        'SELECT orders.user_id, SUM(amount) AS total_spent FROM orders GROUP BY orders.user_id HAVING SUM(amount) > @param_0 AND COUNT(*) < @param_1',
      );
      expect(query.parameters['param_0'], 100);
      expect(query.parameters['param_1'], 10);
    });

    test(
      '35. Should throw SqlBuilderException if HAVING is used without GROUP BY',
      () {
        expect(
          () => SQL
              .select([SQL.column('id')])
              .from(orders)
              .having(SQL.column('amount'), ComparisonOperator.greaterThan, 100)
              .build(),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );
  });

  group('SqlBuilder ORDER BY, LIMIT, OFFSET', () {
    final users = SQL.table('users');

    test('36. Should build an ORDER BY ASC clause', () {
      final query = SQL
          .selectAll()
          .from(users)
          .orderBy(users.col('name'), OrderDirection.asc)
          .build();
      expect(query, 'SELECT * FROM users ORDER BY users.name ASC');
    });

    test('37. Should build an ORDER BY DESC clause', () {
      final query = SQL
          .selectAll()
          .from(users)
          .orderBy(users.col('created_at'), OrderDirection.desc)
          .build();
      expect(query, 'SELECT * FROM users ORDER BY users.created_at DESC');
    });

    test('38. Should build ORDER BY with multiple columns', () {
      final query = SQL.selectAll().from(users).orderByMultiple([
        users.col('age').asc,
        users.col('name').desc,
      ]).build();
      expect(
        query,
        'SELECT * FROM users ORDER BY users.age ASC, users.name DESC',
      );
    });

    test('39. Should build a LIMIT clause', () {
      final query = SQL.selectAll().from(users).limit(10).build();
      expect(query, 'SELECT * FROM users LIMIT 10');
    });

    test('40. Should build an OFFSET clause (requires LIMIT)', () {
      final query = SQL.selectAll().from(users).limit(10).offset(20).build();
      expect(query, 'SELECT * FROM users LIMIT 10 OFFSET 20');
    });

    test(
      '41. Should throw SqlBuilderException if OFFSET is used without LIMIT',
      () {
        expect(
          () => SQL.selectAll().from(users).offset(10).build(),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );

    test('42. Should throw SqlBuilderException for negative LIMIT', () {
      expect(
        () => SQL.selectAll().from(users).limit(-5).build(),
        throwsA(isA<SqlBuilderException>()),
      );
    });

    test('43. Should throw SqlBuilderException for zero LIMIT', () {
      expect(
        () => SQL.selectAll().from(users).limit(0).build(),
        throwsA(isA<SqlBuilderException>()),
      );
    });

    test('44. Should throw SqlBuilderException for negative OFFSET', () {
      expect(
        () => SQL.selectAll().from(users).offset(-5).build(),
        throwsA(isA<SqlBuilderException>()),
      );
    });
  });

  group('SqlBuilder Aggregate Functions', () {
    final products = SQL.table('products');

    test('45. Should build COUNT(column) query', () {
      final query = SQL
          .select([
            SQL.count('product_id', table: products).as('total_products'),
          ])
          .from(products)
          .build();
      expect(
        query,
        'SELECT COUNT(products.product_id) AS total_products FROM products',
      );
    });

    test('46. Should build SUM(column) query', () {
      final query = SQL
          .select([SQL.sum('price', table: products).as('total_price')])
          .from(products)
          .build();
      expect(query, 'SELECT SUM(products.price) AS total_price FROM products');
    });

    test('47. Should build AVG(column) query', () {
      final query = SQL
          .select([SQL.avg('rating', table: products).as('average_rating')])
          .from(products)
          .build();
      expect(
        query,
        'SELECT AVG(products.rating) AS average_rating FROM products',
      );
    });

    test('48. Should build MIN(column) query', () {
      final query = SQL
          .select([SQL.min('stock_quantity', table: products).as('min_stock')])
          .from(products)
          .build();
      expect(
        query,
        'SELECT MIN(products.stock_quantity) AS min_stock FROM products',
      );
    });

    test('49. Should build MAX(column) query', () {
      final query = SQL
          .select([
            SQL.max('creation_date', table: products).as('latest_product'),
          ])
          .from(products)
          .build();
      expect(
        query,
        'SELECT MAX(products.creation_date) AS latest_product FROM products',
      );
    });

    test('50. Should build COUNT(DISTINCT column) query', () {
      final query = SQL
          .select([
            SQL
                .count('category', table: products, distinct: true)
                .as('distinct_categories'),
          ])
          .from(products)
          .build();
      expect(
        query,
        'SELECT COUNT(DISTINCT products.category) AS distinct_categories FROM products',
      );
    });
  });

  group('SqlBuilder Parameterization and QueryResult', () {
    test('51. Should return correct SQL and parameters for a simple query', () {
      final users = SQL.table('users');
      final queryResult = SQL
          .selectAll()
          .from(users)
          .where(users.col('name'), ComparisonOperator.equals, 'Alice')
          .andWhere(users.col('age'), ComparisonOperator.greaterThan, 30)
          .buildResult();

      expect(
        queryResult.sql,
        'SELECT * FROM users WHERE users.name = @param_0 AND users.age > @param_1',
      );
      expect(queryResult.parameters, {'param_0': 'Alice', 'param_1': 30});
    });

    test('52. Should return empty parameters if no WHERE/HAVING clause', () {
      final users = SQL.table('users');
      final queryResult = SQL.selectAll().from(users).buildResult();
      expect(queryResult.sql, 'SELECT * FROM users');
      expect(queryResult.parameters, isEmpty);
    });
  });

  group('SqlBuilder Reset Functionality', () {
    test('53. Should reset the builder to its initial state', () {
      final builder = SQL
          .selectAll()
          .from(SQL.table('users'))
          .where(SQL.column('id'), ComparisonOperator.equals, 1)
          .limit(10);

      final initialQuery = builder.build();
      expect(initialQuery, 'SELECT * FROM users WHERE id = @param_0 LIMIT 10');

      builder.reset();
      final resetQuery = builder
          .select([SQL.column('name')])
          .from(SQL.table('products'))
          .build();
      expect(resetQuery, 'SELECT name FROM products');

      final resetParameters = builder.getParameters();
      expect(resetParameters, isEmpty);
    });
  });

  group('SqlBuilder Identifier Validation', () {
    test('54. Should throw SqlBuilderException for empty table name', () {
      expect(() => SQL.table(''), throwsA(isA<SqlBuilderException>()));
    });

    test(
      '55. Should throw SqlBuilderException for SQL keyword as table name',
      () {
        expect(() => SQL.table('SELECT'), throwsA(isA<SqlBuilderException>()));
      },
    );

    test(
      '56. Should throw SqlBuilderException for invalid table name characters',
      () {
        expect(
          () => SQL.table('my-table'),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );

    test('57. Should throw SqlBuilderException for too long table name', () {
      final longName = 'a' * 64;
      expect(() => SQL.table(longName), throwsA(isA<SqlBuilderException>()));
    });

    test('58. Should throw SqlBuilderException for empty column name', () {
      expect(() => SQL.column(''), throwsA(isA<SqlBuilderException>()));
    });

    test(
      '59. Should throw SqlBuilderException for SQL keyword as column name',
      () {
        expect(() => SQL.column('WHERE'), throwsA(isA<SqlBuilderException>()));
      },
    );

    test(
      '60. Should throw SqlBuilderException for invalid column name characters',
      () {
        expect(
          () => SQL.column('col.name'),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );

    test('69. ColumnReference.eq should create correct condition', () {
      final users = SQL.table('users');
      final condition = users.col('id').eq(10);
      final params = <String, SqlParameter>{};
      final sql = condition.toSql(params);
      expect(sql, 'users.id = @param_0');
      expect(params['param_0']!.value, 10);
    });

    test(
      '62. Should throw SqlBuilderException for GROUP BY column from unknown table',
      () {
        final users = SQL.table('users');
        final orders = SQL.table('orders'); // Not added to FROM/JOIN
        expect(
          () => SQL.selectAll().from(users).groupBy([orders.col('id')]).build(),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );

    test(
      '63. Should throw SqlBuilderException for ORDER BY column from unknown table',
      () {
        final users = SQL.table('users');
        final orders = SQL.table('orders'); // Not added to FROM/JOIN
        expect(
          () => SQL
              .selectAll()
              .from(users)
              .orderBy(orders.col('date'), OrderDirection.desc)
              .build(),
          throwsA(isA<SqlBuilderException>()),
        );
      },
    );
  });

  group('Where convenience methods', () {
    final users = SQL.table('users');

    test('64. Where.equals should create correct clause', () {
      final result = SQL
          .selectAll()
          .from(users)
          .whereGroup(Where.equals(users.col('name'), 'Bob'))
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.name = @param_0');
      expect(result.parameters['param_0'], 'Bob');
    });

    test('65. Where.notEquals should create correct clause', () {
      final result = SQL
          .selectAll()
          .from(users)
          .whereGroup(Where.notEquals(users.col('name'), 'Bob'))
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.name != @param_0');
    });

    test('66. Where.greaterThan should create correct clause', () {
      final result = SQL
          .selectAll()
          .from(users)
          .whereGroup(Where.greaterThan(users.col('age'), 30))
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.age > @param_0');
    });

    test('67. Where.inList should create correct clause', () {
      final result = SQL
          .selectAll()
          .from(users)
          .whereGroup(Where.inList(users.col('status'), ['active', 'pending']))
          .buildResult();
      expect(
        result.sql,
        'SELECT * FROM users WHERE users.status IN (@param_0, @param_1)',
      );
    });

    test('68. Where.isNull should create correct clause', () {
      final result = SQL
          .selectAll()
          .from(users)
          .whereGroup(Where.isNull(users.col('address')))
          .buildResult();
      expect(result.sql, 'SELECT * FROM users WHERE users.address IS NULL');
    });
  });
}
