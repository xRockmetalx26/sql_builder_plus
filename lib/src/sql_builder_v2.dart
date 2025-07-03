// /// SQL Builder Library for Dart
// /// A robust and complete library for generating SQL SELECT queries
// /// with protection against SQL injection and comprehensive validation
// library;

// /// Exception thrown when SQL Builder encounters an error
// class SqlBuilderException implements Exception {
//   final String message;
//   const SqlBuilderException(this.message);

//   @override
//   String toString() => 'SqlBuilderException: $message';
// }

// /// Represents a SQL parameter with its value and type
// class SqlParameter {
//   final String name;
//   final dynamic value;
//   final SqlParameterType type;

//   const SqlParameter(this.name, this.value, this.type);
// }

// /// Types of SQL parameters for proper escaping
// enum SqlParameterType {
//   string,
//   number,
//   boolean,
//   date,
//   list,
//   raw, // Use with extreme caution
// }

// /// Join types supported by the SQL Builder
// enum JoinType { inner, left, right, full, cross }

// /// Order direction for ORDER BY clauses
// enum OrderDirection { asc, desc }

// /// Aggregate functions supported
// enum AggregateFunction { count, sum, avg, min, max, groupConcat }

// /// Comparison operators for WHERE clauses
// enum ComparisonOperator {
//   equals,
//   notEquals,
//   greaterThan,
//   greaterThanOrEqual,
//   lessThan,
//   lessThanOrEqual,
//   like,
//   notLike,
//   isNull,
//   isNotNull,
//   inList,
//   notInList,
//   between,
//   notBetween,
// }

// /// Logical operators for combining conditions
// enum LogicalOperator { and, or }

// /// Represents a column in a SQL query
// class Column {
//   final String name;
//   final String? table;
//   final String? alias;
//   final AggregateFunction? aggregateFunction;

//   const Column(this.name, {this.table, this.alias, this.aggregateFunction});

//   String toSql() {
//     String fullName = table != null ? '$table.$name' : name;

//     if (aggregateFunction != null) {
//       String funcName = aggregateFunction
//           .toString()
//           .split('.')
//           .last
//           .toUpperCase();
//       if (aggregateFunction == AggregateFunction.groupConcat) {
//         funcName = 'GROUP_CONCAT';
//       }
//       fullName = '$funcName($fullName)';
//     }

//     return alias != null ? '$fullName AS $alias' : fullName;
//   }
// }

// /// Represents a JOIN clause
// class Join {
//   final JoinType type;
//   final String table;
//   final String? alias;
//   final String condition;

//   const Join(this.type, this.table, this.condition, {this.alias});

//   String toSql() {
//     String joinType = type.toString().split('.').last.toUpperCase();
//     String tableName = alias != null ? '$table $alias' : table;
//     return '$joinType JOIN $tableName ON $condition';
//   }
// }

// /// Represents a WHERE condition
// class WhereCondition {
//   final String column;
//   final ComparisonOperator operator;
//   final dynamic value;
//   final String? table;

//   const WhereCondition(this.column, this.operator, this.value, {this.table});

//   String toSql(Map<String, SqlParameter> parameters) {
//     String fullColumn = table != null ? '$table.$column' : column;

//     switch (operator) {
//       case ComparisonOperator.equals:
//         return '$fullColumn = ${_parameterize(value, parameters)}';
//       case ComparisonOperator.notEquals:
//         return '$fullColumn != ${_parameterize(value, parameters)}';
//       case ComparisonOperator.greaterThan:
//         return '$fullColumn > ${_parameterize(value, parameters)}';
//       case ComparisonOperator.greaterThanOrEqual:
//         return '$fullColumn >= ${_parameterize(value, parameters)}';
//       case ComparisonOperator.lessThan:
//         return '$fullColumn < ${_parameterize(value, parameters)}';
//       case ComparisonOperator.lessThanOrEqual:
//         return '$fullColumn <= ${_parameterize(value, parameters)}';
//       case ComparisonOperator.like:
//         return '$fullColumn LIKE ${_parameterize(value, parameters)}';
//       case ComparisonOperator.notLike:
//         return '$fullColumn NOT LIKE ${_parameterize(value, parameters)}';
//       case ComparisonOperator.isNull:
//         return '$fullColumn IS NULL';
//       case ComparisonOperator.isNotNull:
//         return '$fullColumn IS NOT NULL';
//       case ComparisonOperator.inList:
//         if (value is! List) {
//           throw SqlBuilderException('IN operator requires a list value');
//         }
//         return '$fullColumn IN (${_parameterizeList(value, parameters)})';
//       case ComparisonOperator.notInList:
//         if (value is! List) {
//           throw SqlBuilderException('NOT IN operator requires a list value');
//         }
//         return '$fullColumn NOT IN (${_parameterizeList(value, parameters)})';
//       case ComparisonOperator.between:
//         if (value is! List || value.length != 2) {
//           throw SqlBuilderException(
//             'BETWEEN operator requires a list with exactly 2 values',
//           );
//         }
//         return '$fullColumn BETWEEN ${_parameterize(value[0], parameters)} AND ${_parameterize(value[1], parameters)}';
//       case ComparisonOperator.notBetween:
//         if (value is! List || value.length != 2) {
//           throw SqlBuilderException(
//             'NOT BETWEEN operator requires a list with exactly 2 values',
//           );
//         }
//         return '$fullColumn NOT BETWEEN ${_parameterize(value[0], parameters)} AND ${_parameterize(value[1], parameters)}';
//     }
//   }

//   String _parameterize(dynamic value, Map<String, SqlParameter> parameters) {
//     String paramName = 'param_${parameters.length}';
//     SqlParameterType type = _inferParameterType(value);
//     parameters[paramName] = SqlParameter(paramName, value, type);
//     return '@$paramName';
//   }

//   String _parameterizeList(List value, Map<String, SqlParameter> parameters) {
//     return value.map((item) => _parameterize(item, parameters)).join(', ');
//   }

//   SqlParameterType _inferParameterType(dynamic value) {
//     if (value is String) return SqlParameterType.string;
//     if (value is num) return SqlParameterType.number;
//     if (value is bool) return SqlParameterType.boolean;
//     if (value is DateTime) return SqlParameterType.date;
//     if (value is List) return SqlParameterType.list;
//     return SqlParameterType.string;
//   }
// }

// /// Represents a complex WHERE clause with logical operators
// class WhereClause {
//   final List<dynamic> conditions = [];

//   WhereClause where(
//     String column,
//     ComparisonOperator operator,
//     dynamic value, {
//     String? table,
//   }) {
//     conditions.add(WhereCondition(column, operator, value, table: table));
//     return this;
//   }

//   WhereClause and(
//     String column,
//     ComparisonOperator operator,
//     dynamic value, {
//     String? table,
//   }) {
//     if (conditions.isNotEmpty) {
//       conditions.add(LogicalOperator.and);
//     }
//     conditions.add(WhereCondition(column, operator, value, table: table));
//     return this;
//   }

//   WhereClause or(
//     String column,
//     ComparisonOperator operator,
//     dynamic value, {
//     String? table,
//   }) {
//     if (conditions.isNotEmpty) {
//       conditions.add(LogicalOperator.or);
//     }
//     conditions.add(WhereCondition(column, operator, value, table: table));
//     return this;
//   }

//   WhereClause andGroup(WhereClause group) {
//     if (conditions.isNotEmpty) {
//       conditions.add(LogicalOperator.and);
//     }
//     conditions.add(group);
//     return this;
//   }

//   WhereClause orGroup(WhereClause group) {
//     if (conditions.isNotEmpty) {
//       conditions.add(LogicalOperator.or);
//     }
//     conditions.add(group);
//     return this;
//   }

//   String toSql(Map<String, SqlParameter> parameters) {
//     if (conditions.isEmpty) return '';

//     StringBuffer buffer = StringBuffer();

//     for (int i = 0; i < conditions.length; i++) {
//       dynamic condition = conditions[i];

//       if (condition is WhereCondition) {
//         buffer.write(condition.toSql(parameters));
//       } else if (condition is LogicalOperator) {
//         buffer.write(' ${condition.toString().split('.').last.toUpperCase()} ');
//       } else if (condition is WhereClause) {
//         buffer.write('(${condition.toSql(parameters)})');
//       }
//     }

//     return buffer.toString();
//   }
// }

// /// Represents an ORDER BY clause
// class OrderBy {
//   final String column;
//   final OrderDirection direction;
//   final String? table;

//   const OrderBy(this.column, this.direction, {this.table});

//   String toSql() {
//     String fullColumn = table != null ? '$table.$column' : column;
//     String dir = direction.toString().split('.').last.toUpperCase();
//     return '$fullColumn $dir';
//   }
// }

// /// Main SQL Builder class
// class SqlBuilder {
//   final List<Column> _selectColumns = [];
//   final List<String> _fromTables = [];
//   final List<Join> _joins = [];
//   final WhereClause _whereClause = WhereClause();
//   final List<String> _groupByColumns = [];
//   final WhereClause _havingClause = WhereClause();
//   final List<OrderBy> _orderByColumns = [];
//   int? _limitCount;
//   int? _offsetCount;
//   final Map<String, SqlParameter> _parameters = {};

//   /// Validation patterns
//   static final RegExp _identifierPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
//   static final RegExp _tableColumnPattern = RegExp(
//     r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)?$',
//   );

//   /// Add SELECT columns
//   SqlBuilder select(List<dynamic> columns) {
//     _selectColumns.clear();

//     for (dynamic col in columns) {
//       if (col is String) {
//         _validateIdentifier(col, 'column');
//         _selectColumns.add(Column(col));
//       } else if (col is Column) {
//         _validateColumn(col);
//         _selectColumns.add(col);
//       } else {
//         throw SqlBuilderException('Invalid column type: ${col.runtimeType}');
//       }
//     }

//     return this;
//   }

//   /// Add FROM tables
//   SqlBuilder from(dynamic tables) {
//     _fromTables.clear();

//     if (tables is String) {
//       _validateIdentifier(tables, 'table');
//       _fromTables.add(tables);
//     } else if (tables is List<String>) {
//       for (String table in tables) {
//         _validateIdentifier(table, 'table');
//         _fromTables.add(table);
//       }
//     } else {
//       throw SqlBuilderException(
//         'FROM clause must be a string or list of strings',
//       );
//     }

//     return this;
//   }

//   /// Add JOIN clauses
//   SqlBuilder join(
//     JoinType type,
//     String table,
//     String condition, {
//     String? alias,
//   }) {
//     _validateIdentifier(table, 'table');
//     if (alias != null) _validateIdentifier(alias, 'alias');
//     _validateJoinCondition(condition);

//     _joins.add(Join(type, table, condition, alias: alias));
//     return this;
//   }

//   /// Convenience methods for specific JOIN types
//   SqlBuilder innerJoin(String table, String condition, {String? alias}) =>
//       join(JoinType.inner, table, condition, alias: alias);

//   SqlBuilder leftJoin(String table, String condition, {String? alias}) =>
//       join(JoinType.left, table, condition, alias: alias);

//   SqlBuilder rightJoin(String table, String condition, {String? alias}) =>
//       join(JoinType.right, table, condition, alias: alias);

//   SqlBuilder fullJoin(String table, String condition, {String? alias}) =>
//       join(JoinType.full, table, condition, alias: alias);

//   /// Add WHERE conditions
//   SqlBuilder where(
//     String column,
//     ComparisonOperator operator,
//     dynamic value, {
//     String? table,
//   }) {
//     _whereClause.where(column, operator, value, table: table);
//     return this;
//   }

//   SqlBuilder whereGroup(WhereClause group) {
//     _whereClause.andGroup(group);
//     return this;
//   }

//   /// Add GROUP BY columns
//   SqlBuilder groupBy(List<String> columns) {
//     _groupByColumns.clear();

//     for (String column in columns) {
//       _validateTableColumn(column);
//       _groupByColumns.add(column);
//     }

//     return this;
//   }

//   /// Add HAVING conditions
//   SqlBuilder having(
//     String column,
//     ComparisonOperator operator,
//     dynamic value, {
//     String? table,
//   }) {
//     _havingClause.where(column, operator, value, table: table);
//     return this;
//   }

//   SqlBuilder havingGroup(WhereClause group) {
//     _havingClause.andGroup(group);
//     return this;
//   }

//   /// Add ORDER BY columns
//   SqlBuilder orderBy(String column, OrderDirection direction, {String? table}) {
//     _validateTableColumn(column);
//     _orderByColumns.add(OrderBy(column, direction, table: table));
//     return this;
//   }

//   /// Add multiple ORDER BY columns
//   SqlBuilder orderByMultiple(List<OrderBy> orders) {
//     for (OrderBy order in orders) {
//       _validateTableColumn(order.column);
//       _orderByColumns.add(order);
//     }
//     return this;
//   }

//   /// Set LIMIT
//   SqlBuilder limit(int count) {
//     if (count < 0) throw SqlBuilderException('LIMIT must be non-negative');
//     _limitCount = count;
//     return this;
//   }

//   /// Set OFFSET
//   SqlBuilder offset(int count) {
//     if (count < 0) throw SqlBuilderException('OFFSET must be non-negative');
//     _offsetCount = count;
//     return this;
//   }

//   /// Build the complete SQL query
//   String build() {
//     _validateQuery();

//     StringBuffer sql = StringBuffer();

//     // SELECT clause
//     sql.write('SELECT ');
//     if (_selectColumns.isEmpty) {
//       sql.write('*');
//     } else {
//       sql.write(_selectColumns.map((col) => col.toSql()).join(', '));
//     }

//     // FROM clause
//     if (_fromTables.isNotEmpty) {
//       sql.write(' FROM ${_fromTables.join(', ')}');
//     }

//     // JOIN clauses
//     for (Join join in _joins) {
//       sql.write(' ${join.toSql()}');
//     }

//     // WHERE clause
//     String whereClause = _whereClause.toSql(_parameters);
//     if (whereClause.isNotEmpty) {
//       sql.write(' WHERE $whereClause');
//     }

//     // GROUP BY clause
//     if (_groupByColumns.isNotEmpty) {
//       sql.write(' GROUP BY ${_groupByColumns.join(', ')}');
//     }

//     // HAVING clause
//     String havingClause = _havingClause.toSql(_parameters);
//     if (havingClause.isNotEmpty) {
//       sql.write(' HAVING $havingClause');
//     }

//     // ORDER BY clause
//     if (_orderByColumns.isNotEmpty) {
//       sql.write(
//         ' ORDER BY ${_orderByColumns.map((o) => o.toSql()).join(', ')}',
//       );
//     }

//     // LIMIT clause
//     if (_limitCount != null) {
//       sql.write(' LIMIT $_limitCount');
//     }

//     // OFFSET clause
//     if (_offsetCount != null) {
//       sql.write(' OFFSET $_offsetCount');
//     }

//     return sql.toString().trim();
//   }

//   /// Get parameters for prepared statements
//   Map<String, SqlParameter> getParameters() {
//     return Map.unmodifiable(_parameters);
//   }

//   /// Get parameter values only
//   Map<String, dynamic> getParameterValues() {
//     return _parameters.map((key, param) => MapEntry(key, param.value));
//   }

//   /// Reset the builder
//   SqlBuilder reset() {
//     _selectColumns.clear();
//     _fromTables.clear();
//     _joins.clear();
//     _whereClause.conditions.clear();
//     _groupByColumns.clear();
//     _havingClause.conditions.clear();
//     _orderByColumns.clear();
//     _limitCount = null;
//     _offsetCount = null;
//     _parameters.clear();
//     return this;
//   }

//   /// Validation methods
//   void _validateIdentifier(String identifier, String type) {
//     if (identifier.isEmpty) {
//       throw SqlBuilderException('$type name cannot be empty');
//     }

//     if (!_identifierPattern.hasMatch(identifier)) {
//       throw SqlBuilderException(
//         'Invalid $type name: $identifier. Must contain only letters, numbers, and underscores, and start with a letter or underscore',
//       );
//     }

//     // Check for SQL keywords
//     if (_isSqlKeyword(identifier)) {
//       throw SqlBuilderException(
//         '$type name cannot be a SQL keyword: $identifier',
//       );
//     }
//   }

//   void _validateTableColumn(String column) {
//     if (column.isEmpty) {
//       throw SqlBuilderException('Column name cannot be empty');
//     }

//     if (!_tableColumnPattern.hasMatch(column)) {
//       throw SqlBuilderException('Invalid column name: $column');
//     }
//   }

//   void _validateColumn(Column column) {
//     _validateIdentifier(column.name, 'column');
//     if (column.table != null) {
//       _validateIdentifier(column.table!, 'table');
//     }
//     if (column.alias != null) {
//       _validateIdentifier(column.alias!, 'alias');
//     }
//   }

//   void _validateJoinCondition(String condition) {
//     if (condition.isEmpty) {
//       throw SqlBuilderException('JOIN condition cannot be empty');
//     }

//     // Basic validation - in a real implementation, you might want more sophisticated parsing
//     if (!condition.contains('=') && !condition.contains('ON')) {
//       throw SqlBuilderException(
//         'JOIN condition must contain a comparison operator',
//       );
//     }
//   }

//   void _validateQuery() {
//     if (_fromTables.isEmpty && _joins.isEmpty) {
//       throw SqlBuilderException(
//         'Query must have at least one FROM table or JOIN',
//       );
//     }
//   }

//   bool _isSqlKeyword(String word) {
//     const keywords = {
//       'SELECT',
//       'FROM',
//       'WHERE',
//       'JOIN',
//       'INNER',
//       'LEFT',
//       'RIGHT',
//       'FULL',
//       'ON',
//       'GROUP',
//       'BY',
//       'HAVING',
//       'ORDER',
//       'LIMIT',
//       'OFFSET',
//       'AS',
//       'AND',
//       'OR',
//       'NOT',
//       'NULL',
//       'IS',
//       'IN',
//       'BETWEEN',
//       'LIKE',
//       'EXISTS',
//       'UNION',
//       'ALL',
//       'DISTINCT',
//       'COUNT',
//       'SUM',
//       'AVG',
//       'MIN',
//       'MAX',
//       'INSERT',
//       'UPDATE',
//       'DELETE',
//       'CREATE',
//       'DROP',
//       'ALTER',
//       'TABLE',
//       'DATABASE',
//       'INDEX',
//       'VIEW',
//     };

//     return keywords.contains(word.toUpperCase());
//   }
// }

// /// Utility class for creating WHERE clauses
// class Where {
//   static WhereClause create() => WhereClause();

//   static WhereClause equals(String column, dynamic value, {String? table}) =>
//       WhereClause().where(
//         column,
//         ComparisonOperator.equals,
//         value,
//         table: table,
//       );

//   static WhereClause notEquals(String column, dynamic value, {String? table}) =>
//       WhereClause().where(
//         column,
//         ComparisonOperator.notEquals,
//         value,
//         table: table,
//       );

//   static WhereClause greaterThan(
//     String column,
//     dynamic value, {
//     String? table,
//   }) => WhereClause().where(
//     column,
//     ComparisonOperator.greaterThan,
//     value,
//     table: table,
//   );

//   static WhereClause lessThan(String column, dynamic value, {String? table}) =>
//       WhereClause().where(
//         column,
//         ComparisonOperator.lessThan,
//         value,
//         table: table,
//       );

//   static WhereClause like(String column, String pattern, {String? table}) =>
//       WhereClause().where(
//         column,
//         ComparisonOperator.like,
//         pattern,
//         table: table,
//       );

//   static WhereClause inList(String column, List values, {String? table}) =>
//       WhereClause().where(
//         column,
//         ComparisonOperator.inList,
//         values,
//         table: table,
//       );

//   static WhereClause between(
//     String column,
//     dynamic start,
//     dynamic end, {
//     String? table,
//   }) => WhereClause().where(column, ComparisonOperator.between, [
//     start,
//     end,
//   ], table: table);

//   static WhereClause isNull(String column, {String? table}) => WhereClause()
//       .where(column, ComparisonOperator.isNull, null, table: table);

//   static WhereClause isNotNull(String column, {String? table}) => WhereClause()
//       .where(column, ComparisonOperator.isNotNull, null, table: table);
// }

// /// Factory class for creating SQL Builder instances
// class SQL {
//   static SqlBuilder select([List<dynamic>? columns]) {
//     SqlBuilder builder = SqlBuilder();
//     if (columns != null) {
//       builder.select(columns);
//     }
//     return builder;
//   }

//   static Column column(
//     String name, {
//     String? table,
//     String? alias,
//     AggregateFunction? aggregate,
//   }) {
//     return Column(
//       name,
//       table: table,
//       alias: alias,
//       aggregateFunction: aggregate,
//     );
//   }

//   static OrderBy orderBy(
//     String column,
//     OrderDirection direction, {
//     String? table,
//   }) {
//     return OrderBy(column, direction, table: table);
//   }
// }
