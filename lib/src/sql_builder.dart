/// SQL Builder Library for Dart
/// A robust and type-safe library for generating SQL SELECT queries
/// with strong typing and protection against SQL injection
library;

/// Exception thrown when SQL Builder encounters an error
class SqlBuilderException implements Exception {
  final String message;
  const SqlBuilderException(this.message);

  @override
  String toString() => 'SqlBuilderException: $message';
}

/// Represents a SQL parameter with its value and type
class SqlParameter {
  final String name;
  final dynamic value;
  final SqlParameterType type;

  const SqlParameter(this.name, this.value, this.type);
}

/// Types of SQL parameters for proper escaping
enum SqlParameterType {
  string,
  number,
  boolean,
  date,
  list,
  raw, // Use with extreme caution
}

/// Join types supported by the SQL Builder
enum JoinType { inner, left, right, full, cross }

/// Order direction for ORDER BY clauses
enum OrderDirection { asc, desc }

/// Aggregate functions supported
enum AggregateFunction { count, sum, avg, min, max, groupConcat }

/// Comparison operators for WHERE clauses
enum ComparisonOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  like,
  notLike,
  iLike,
  notILike,
  isNull,
  isNotNull,
  inList,
  notInList,
  between,
  notBetween,
  exists,
  notExists,
}

/// Logical operators for combining conditions
enum LogicalOperator { and, or }

/// Represents a table reference with optional alias
class TableReference {
  final String tableName;
  final String? alias;

  const TableReference(this.tableName, {this.alias});

  /// Create a table reference with alias
  TableReference as(String alias) {
    _validateIdentifier(alias, 'table alias');
    return TableReference(tableName, alias: alias);
  }

  /// Get the reference name (alias if exists, otherwise table name)
  String get referenceName => alias ?? tableName;

  String toSql() {
    if (alias != null) {
      return '$tableName AS $alias';
    }
    return tableName;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableReference &&
          runtimeType == other.runtimeType &&
          tableName == other.tableName &&
          alias == other.alias;

  @override
  int get hashCode => tableName.hashCode ^ alias.hashCode;
}

/// Represents a column reference with table context
class ColumnReference {
  final String columnName;
  final TableReference? table;
  final String? alias;
  final AggregateFunction? aggregateFunction;
  final bool isDistinct;

  const ColumnReference(
    this.columnName, {
    this.table,
    this.alias,
    this.aggregateFunction,
    this.isDistinct = false,
  });

  /// Create a column reference with alias
  ColumnReference as(String alias) {
    _validateIdentifier(alias, 'column alias');
    return ColumnReference(
      columnName,
      table: table,
      alias: alias,
      aggregateFunction: aggregateFunction,
      isDistinct: isDistinct,
    );
  }

  /// Create a column reference with aggregate function
  ColumnReference withAggregate(
    AggregateFunction function, {
    bool distinct = false,
  }) {
    return ColumnReference(
      columnName,
      table: table,
      alias: alias,
      aggregateFunction: function,
      isDistinct: distinct,
    );
  }

  /// Get the full column reference (table.column or column)
  String get fullName {
    if (table != null) {
      return '${table!.referenceName}.$columnName';
    }
    return columnName;
  }

  String toSql() {
    String name = fullName;

    if (aggregateFunction != null) {
      String funcName = _getFunctionName(aggregateFunction!);
      if (isDistinct) {
        name = '$funcName(DISTINCT $name)';
      } else {
        name = '$funcName($name)';
      }
    }

    return alias != null ? '$name AS $alias' : name;
  }

  String _getFunctionName(AggregateFunction function) {
    switch (function) {
      case AggregateFunction.count:
        return 'COUNT';
      case AggregateFunction.sum:
        return 'SUM';
      case AggregateFunction.avg:
        return 'AVG';
      case AggregateFunction.min:
        return 'MIN';
      case AggregateFunction.max:
        return 'MAX';
      case AggregateFunction.groupConcat:
        return 'GROUP_CONCAT';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnReference &&
          runtimeType == other.runtimeType &&
          columnName == other.columnName &&
          table == other.table &&
          alias == other.alias &&
          aggregateFunction == other.aggregateFunction &&
          isDistinct == other.isDistinct;

  @override
  int get hashCode =>
      columnName.hashCode ^
      table.hashCode ^
      alias.hashCode ^
      aggregateFunction.hashCode ^
      isDistinct.hashCode;
}

/// Represents a JOIN condition with strong typing
class JoinCondition {
  final ColumnReference leftColumn;
  final ColumnReference rightColumn;
  final ComparisonOperator operator;

  const JoinCondition(
    this.leftColumn,
    this.rightColumn, {
    this.operator = ComparisonOperator.equals,
  });

  /// Create an equality join condition
  static JoinCondition on(ColumnReference left, ColumnReference right) {
    return JoinCondition(left, right);
  }

  /// Create a join condition with custom operator
  static JoinCondition onWith(
    ColumnReference left,
    ColumnReference right,
    ComparisonOperator operator,
  ) {
    return JoinCondition(left, right, operator: operator);
  }

  String toSql() {
    String op = _getOperatorSql(operator);
    return '${leftColumn.fullName} $op ${rightColumn.fullName}';
  }

  String _getOperatorSql(ComparisonOperator operator) {
    switch (operator) {
      case ComparisonOperator.equals:
        return '=';
      case ComparisonOperator.notEquals:
        return '!=';
      case ComparisonOperator.greaterThan:
        return '>';
      case ComparisonOperator.greaterThanOrEqual:
        return '>=';
      case ComparisonOperator.lessThan:
        return '<';
      case ComparisonOperator.lessThanOrEqual:
        return '<=';
      default:
        throw SqlBuilderException('Unsupported operator for JOIN: $operator');
    }
  }
}

/// Represents a JOIN clause with strong typing
class JoinClause {
  final JoinType type;
  final TableReference table;
  final JoinCondition condition;

  const JoinClause(this.type, this.table, this.condition);

  String toSql() {
    String joinTypeSql = _getJoinTypeSql(type);
    return '$joinTypeSql JOIN ${table.toSql()} ON ${condition.toSql()}';
  }

  String _getJoinTypeSql(JoinType type) {
    switch (type) {
      case JoinType.inner:
        return 'INNER';
      case JoinType.left:
        return 'LEFT';
      case JoinType.right:
        return 'RIGHT';
      case JoinType.full:
        return 'FULL OUTER';
      case JoinType.cross:
        return 'CROSS';
    }
  }
}

/// Represents a WHERE condition with strong typing
class WhereCondition {
  final ColumnReference column;
  final ComparisonOperator operator;
  final dynamic value;

  const WhereCondition(this.column, this.operator, this.value);

  String toSql(Map<String, SqlParameter> parameters) {
    String columnSql = column.aggregateFunction != null
        ? column.toSql()
        : column.fullName;

    switch (operator) {
      case ComparisonOperator.equals:
        return '$columnSql = ${_parameterize(value, parameters)}';
      case ComparisonOperator.notEquals:
        return '$columnSql != ${_parameterize(value, parameters)}';
      case ComparisonOperator.greaterThan:
        return '$columnSql > ${_parameterize(value, parameters)}';
      case ComparisonOperator.greaterThanOrEqual:
        return '$columnSql >= ${_parameterize(value, parameters)}';
      case ComparisonOperator.lessThan:
        return '$columnSql < ${_parameterize(value, parameters)}';
      case ComparisonOperator.lessThanOrEqual:
        return '$columnSql <= ${_parameterize(value, parameters)}';
      case ComparisonOperator.like:
        return '$columnSql LIKE ${_parameterize(value, parameters)}';
      case ComparisonOperator.notLike:
        return '$columnSql NOT LIKE ${_parameterize(value, parameters)}';
      case ComparisonOperator.iLike:
        return '$columnSql ILIKE ${_parameterize(value, parameters)}';
      case ComparisonOperator.notILike:
        return '$columnSql NOT ILIKE ${_parameterize(value, parameters)}';
      case ComparisonOperator.isNull:
        return '$columnSql IS NULL';
      case ComparisonOperator.isNotNull:
        return '$columnSql IS NOT NULL';
      case ComparisonOperator.inList:
        if (value is! List) {
          throw SqlBuilderException('IN operator requires a list value');
        }
        if ((value as List).isEmpty) {
          throw SqlBuilderException('IN operator requires a non-empty list');
        }
        return '$columnSql IN (${_parameterizeList(value, parameters)})';
      case ComparisonOperator.notInList:
        if (value is! List) {
          throw SqlBuilderException('NOT IN operator requires a list value');
        }
        if ((value as List).isEmpty) {
          throw SqlBuilderException(
            'NOT IN operator requires a non-empty list',
          );
        }
        return '$columnSql NOT IN (${_parameterizeList(value, parameters)})';
      case ComparisonOperator.between:
        if (value is! List || value.length != 2) {
          throw SqlBuilderException(
            'BETWEEN operator requires a list with exactly 2 values',
          );
        }
        return '$columnSql BETWEEN ${_parameterize(value[0], parameters)} AND ${_parameterize(value[1], parameters)}';
      case ComparisonOperator.notBetween:
        if (value is! List || value.length != 2) {
          throw SqlBuilderException(
            'NOT BETWEEN operator requires a list with exactly 2 values',
          );
        }
        return '$columnSql NOT BETWEEN ${_parameterize(value[0], parameters)} AND ${_parameterize(value[1], parameters)}';
      case ComparisonOperator.exists:
        if (value is! SqlBuilder) {
          throw SqlBuilderException(
            'EXISTS operator requires a SqlBuilder subquery',
          );
        }
        return 'EXISTS (${(value as SqlBuilder).build()})';
      case ComparisonOperator.notExists:
        if (value is! SqlBuilder) {
          throw SqlBuilderException(
            'NOT EXISTS operator requires a SqlBuilder subquery',
          );
        }
        return 'NOT EXISTS (${(value as SqlBuilder).build()})';
    }
  }

  String _parameterize(dynamic value, Map<String, SqlParameter> parameters) {
    if (value is ColumnReference) return value.fullName;

    String paramName = 'param_${parameters.length}';
    SqlParameterType type = _inferParameterType(value);
    parameters[paramName] = SqlParameter(paramName, value, type);
    return '@$paramName';
  }

  String _parameterizeList(List value, Map<String, SqlParameter> parameters) {
    return value.map((item) => _parameterize(item, parameters)).join(', ');
  }

  SqlParameterType _inferParameterType(dynamic value) {
    if (value is String) return SqlParameterType.string;
    if (value is num) return SqlParameterType.number;
    if (value is bool) return SqlParameterType.boolean;
    if (value is DateTime) return SqlParameterType.date;
    if (value is List) return SqlParameterType.list;
    return SqlParameterType.string;
  }
}

/// Represents a complex WHERE clause with logical operators
class WhereClause {
  final List<dynamic> _conditions = [];

  /// Add a WHERE condition
  WhereClause where(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    _conditions.add(WhereCondition(column, operator, value));
    return this;
  }

  /// Add an AND condition
  WhereClause and(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    if (_conditions.isNotEmpty) {
      _conditions.add(LogicalOperator.and);
    }
    _conditions.add(WhereCondition(column, operator, value));
    return this;
  }

  /// Add an OR condition
  WhereClause or(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    if (_conditions.isNotEmpty) {
      _conditions.add(LogicalOperator.or);
    }
    _conditions.add(WhereCondition(column, operator, value));
    return this;
  }

  /// Add an AND group
  WhereClause andGroup(WhereClause group) {
    if (group._conditions.isEmpty) return this;
    if (_conditions.isNotEmpty) {
      _conditions.add(LogicalOperator.and);
    }
    _conditions.add(group);
    return this;
  }

  /// Add an OR group
  WhereClause orGroup(WhereClause group) {
    if (group._conditions.isEmpty) return this;
    if (_conditions.isNotEmpty) {
      _conditions.add(LogicalOperator.or);
    }
    _conditions.add(group);
    return this;
  }

  /// Check if clause is empty
  bool get isEmpty => _conditions.isEmpty;

  String toSql(Map<String, SqlParameter> parameters) {
    if (_conditions.isEmpty) return '';

    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < _conditions.length; i++) {
      dynamic condition = _conditions[i];

      if (condition is WhereCondition) {
        buffer.write(condition.toSql(parameters));
      } else if (condition is LogicalOperator) {
        buffer.write(' ${condition.toString().split('.').last.toUpperCase()} ');
      } else if (condition is WhereClause) {
        buffer.write(condition.toSql(parameters));
      }
    }

    return buffer.toString();
  }
}

/// Represents an ORDER BY clause with strong typing
class OrderByClause {
  final ColumnReference column;
  final OrderDirection direction;

  const OrderByClause(this.column, this.direction);

  String toSql() {
    String directionSql = direction == OrderDirection.asc ? 'ASC' : 'DESC';
    return '${column.fullName} $directionSql';
  }
}

/// Main SQL Builder class with strong typing
class SqlBuilder {
  final List<ColumnReference> _selectColumns = [];
  final List<TableReference> _fromTables = [];
  final List<JoinClause> _joins = [];
  final WhereClause _whereClause = WhereClause();
  final List<ColumnReference> _groupByColumns = [];
  final WhereClause _havingClause = WhereClause();
  final List<OrderByClause> _orderByColumns = [];
  int? _limitCount;
  int? _offsetCount;
  bool _isDistinct = false;
  final Map<String, SqlParameter> _parameters = {};

  /// Add SELECT columns with strong typing
  SqlBuilder select(List<ColumnReference> columns) {
    if (columns.isEmpty) {
      throw SqlBuilderException('SELECT must have at least one column');
    }

    _selectColumns.clear();
    _selectColumns.addAll(columns);
    return this;
  }

  /// Select all columns
  SqlBuilder selectAll() {
    _selectColumns.clear();
    return this;
  }

  /// Add DISTINCT to SELECT
  SqlBuilder distinct() {
    _isDistinct = true;
    return this;
  }

  /// Add FROM table with strong typing
  SqlBuilder from(TableReference table) {
    _fromTables.clear();
    _fromTables.add(table);
    return this;
  }

  /// Add multiple FROM tables
  SqlBuilder fromTables(List<TableReference> tables) {
    if (tables.isEmpty) {
      throw SqlBuilderException('FROM must have at least one table');
    }

    _fromTables.clear();
    _fromTables.addAll(tables);
    return this;
  }

  /// Add JOIN clause with strong typing
  SqlBuilder join(
    JoinType type,
    TableReference table,
    JoinCondition condition,
  ) {
    _joins.add(JoinClause(type, table, condition));
    return this;
  }

  /// Convenience methods for specific JOIN types
  SqlBuilder innerJoin(TableReference table, JoinCondition condition) =>
      join(JoinType.inner, table, condition);

  SqlBuilder leftJoin(TableReference table, JoinCondition condition) =>
      join(JoinType.left, table, condition);

  SqlBuilder rightJoin(TableReference table, JoinCondition condition) =>
      join(JoinType.right, table, condition);

  SqlBuilder fullJoin(TableReference table, JoinCondition condition) =>
      join(JoinType.full, table, condition);

  SqlBuilder crossJoin(TableReference table) => join(
    JoinType.cross,
    table,
    JoinCondition(ColumnReference('1'), ColumnReference('1')),
  ); // Dummy condition for cross join

  /// Add WHERE conditions with strong typing
  SqlBuilder where(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    _whereClause.where(column, operator, value);
    return this;
  }

  /// Add WHERE group
  SqlBuilder whereGroup(WhereClause group) {
    _whereClause.andGroup(group);
    return this;
  }

  /// Add GROUP BY columns with strong typing
  SqlBuilder groupBy(List<ColumnReference> columns) {
    if (columns.isEmpty) {
      throw SqlBuilderException('GROUP BY must have at least one column');
    }

    _groupByColumns.clear();
    _groupByColumns.addAll(columns);
    return this;
  }

  /// Add HAVING conditions with strong typing
  SqlBuilder having(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    _havingClause.where(column, operator, value);
    return this;
  }

  /// Add HAVING group
  SqlBuilder havingGroup(WhereClause group) {
    _havingClause.andGroup(group);
    return this;
  }

  /// Add ORDER BY columns with strong typing
  SqlBuilder orderBy(ColumnReference column, OrderDirection direction) {
    _orderByColumns.add(OrderByClause(column, direction));
    return this;
  }

  /// Add multiple ORDER BY columns
  SqlBuilder orderByMultiple(List<OrderByClause> orders) {
    if (orders.isEmpty) {
      throw SqlBuilderException('ORDER BY must have at least one column');
    }

    _orderByColumns.addAll(orders);
    return this;
  }

  /// Set LIMIT with validation
  SqlBuilder limit(int count) {
    if (count < 0) throw SqlBuilderException('LIMIT must be non-negative');
    if (count == 0) throw SqlBuilderException('LIMIT must be greater than 0');
    _limitCount = count;
    return this;
  }

  /// Set OFFSET with validation
  SqlBuilder offset(int count) {
    if (count < 0) throw SqlBuilderException('OFFSET must be non-negative');
    _offsetCount = count;
    return this;
  }

  /// Build the complete SQL query
  String build() {
    _validateQuery();

    StringBuffer sql = StringBuffer();

    // SELECT clause
    sql.write('SELECT ');
    if (_isDistinct) {
      sql.write('DISTINCT ');
    }

    if (_selectColumns.isEmpty) {
      sql.write('*');
    } else {
      sql.write(_selectColumns.map((col) => col.toSql()).join(', '));
    }

    // FROM clause
    if (_fromTables.isNotEmpty) {
      sql.write(' FROM ${_fromTables.map((t) => t.toSql()).join(', ')}');
    }

    // JOIN clauses
    for (JoinClause join in _joins) {
      sql.write(' ${join.toSql()}');
    }

    // WHERE clause
    if (!_whereClause.isEmpty) {
      sql.write(' WHERE ${_whereClause.toSql(_parameters)}');
    }

    // GROUP BY clause
    if (_groupByColumns.isNotEmpty) {
      sql.write(
        ' GROUP BY ${_groupByColumns.map((c) => c.fullName).join(', ')}',
      );
    }

    // HAVING clause
    if (!_havingClause.isEmpty) {
      sql.write(' HAVING ${_havingClause.toSql(_parameters)}');
    }

    // ORDER BY clause
    if (_orderByColumns.isNotEmpty) {
      sql.write(
        ' ORDER BY ${_orderByColumns.map((o) => o.toSql()).join(', ')}',
      );
    }

    // LIMIT clause
    if (_limitCount != null) {
      sql.write(' LIMIT $_limitCount');
    }

    // OFFSET clause
    if (_offsetCount != null) {
      sql.write(' OFFSET $_offsetCount');
    }

    return sql.toString().trim();
  }

  /// Get parameters for prepared statements
  Map<String, SqlParameter> getParameters() {
    return Map.unmodifiable(_parameters);
  }

  /// Get parameter values only
  Map<String, dynamic> getParameterValues() {
    return _parameters.map((key, param) => MapEntry(key, param.value));
  }

  /// Reset the builder
  SqlBuilder reset() {
    _selectColumns.clear();
    _fromTables.clear();
    _joins.clear();
    _whereClause._conditions.clear();
    _groupByColumns.clear();
    _havingClause._conditions.clear();
    _orderByColumns.clear();
    _limitCount = null;
    _offsetCount = null;
    _isDistinct = false;
    _parameters.clear();
    return this;
  }

  /// Validation methods
  void _validateQuery() {
    if (_fromTables.isEmpty && _joins.isEmpty) {
      throw SqlBuilderException(
        'Query must have at least one FROM table or JOIN',
      );
    }

    if (_havingClause._conditions.isNotEmpty && _groupByColumns.isEmpty) {
      throw SqlBuilderException('HAVING clause requires GROUP BY');
    }

    if (_offsetCount != null && _limitCount == null) {
      throw SqlBuilderException('OFFSET requires LIMIT');
    }

    // Validate that all columns in SELECT, WHERE, GROUP BY, HAVING, ORDER BY
    // reference valid tables
    _validateColumnReferences();
  }

  void _validateColumnReferences() {
    Set<String> availableTables = _fromTables
        .map((t) => t.referenceName)
        .toSet();
    availableTables.addAll(_joins.map((j) => j.table.referenceName));

    // If no tables specified, allow unqualified columns
    if (availableTables.isEmpty) return;

    // Validate SELECT columns
    for (ColumnReference col in _selectColumns) {
      if (col.table != null &&
          !availableTables.contains(col.table!.referenceName)) {
        throw SqlBuilderException(
          'Column ${col.fullName} references unknown table ${col.table!.referenceName}',
        );
      }
    }

    // Similar validation for GROUP BY and ORDER BY columns
    for (ColumnReference col in _groupByColumns) {
      if (col.table != null &&
          !availableTables.contains(col.table!.referenceName)) {
        throw SqlBuilderException(
          'GROUP BY column ${col.fullName} references unknown table ${col.table!.referenceName}',
        );
      }
    }

    for (OrderByClause order in _orderByColumns) {
      if (order.column.table != null &&
          !availableTables.contains(order.column.table!.referenceName)) {
        throw SqlBuilderException(
          'ORDER BY column ${order.column.fullName} references unknown table ${order.column.table!.referenceName}',
        );
      }
    }
  }
}

/// Utility class for creating WHERE clauses with strong typing
class Where {
  static WhereClause create() => WhereClause();

  static WhereClause equals(ColumnReference column, dynamic value) =>
      WhereClause().where(column, ComparisonOperator.equals, value);

  static WhereClause notEquals(ColumnReference column, dynamic value) =>
      WhereClause().where(column, ComparisonOperator.notEquals, value);

  static WhereClause greaterThan(ColumnReference column, dynamic value) =>
      WhereClause().where(column, ComparisonOperator.greaterThan, value);

  static WhereClause greaterThanOrEqual(
    ColumnReference column,
    dynamic value,
  ) =>
      WhereClause().where(column, ComparisonOperator.greaterThanOrEqual, value);

  static WhereClause lessThan(ColumnReference column, dynamic value) =>
      WhereClause().where(column, ComparisonOperator.lessThan, value);

  static WhereClause lessThanOrEqual(ColumnReference column, dynamic value) =>
      WhereClause().where(column, ComparisonOperator.lessThanOrEqual, value);

  static WhereClause like(ColumnReference column, String pattern) =>
      WhereClause().where(column, ComparisonOperator.like, pattern);

  static WhereClause notLike(ColumnReference column, String pattern) =>
      WhereClause().where(column, ComparisonOperator.notLike, pattern);

  static WhereClause iLike(ColumnReference column, String pattern) =>
      WhereClause().where(column, ComparisonOperator.iLike, pattern);

  static WhereClause inList(ColumnReference column, List values) =>
      WhereClause().where(column, ComparisonOperator.inList, values);

  static WhereClause notInList(ColumnReference column, List values) =>
      WhereClause().where(column, ComparisonOperator.notInList, values);

  static WhereClause between(
    ColumnReference column,
    dynamic start,
    dynamic end,
  ) => WhereClause().where(column, ComparisonOperator.between, [start, end]);

  static WhereClause notBetween(
    ColumnReference column,
    dynamic start,
    dynamic end,
  ) => WhereClause().where(column, ComparisonOperator.notBetween, [start, end]);

  static WhereClause isNull(ColumnReference column) =>
      WhereClause().where(column, ComparisonOperator.isNull, null);

  static WhereClause isNotNull(ColumnReference column) =>
      WhereClause().where(column, ComparisonOperator.isNotNull, null);

  static WhereClause exists(SqlBuilder subquery) => WhereClause().where(
    ColumnReference('1'),
    ComparisonOperator.exists,
    subquery,
  );

  static WhereClause notExists(SqlBuilder subquery) => WhereClause().where(
    ColumnReference('1'),
    ComparisonOperator.notExists,
    subquery,
  );
}

/// Factory class for creating SQL Builder instances with strong typing
class SQL {
  /// Create a new SQL Builder
  static SqlBuilder select(List<ColumnReference> columns) {
    return SqlBuilder().select(columns);
  }

  /// Create a SQL Builder with SELECT *
  static SqlBuilder selectAll() {
    return SqlBuilder().selectAll();
  }

  /// Create a table reference
  static TableReference table(String name) {
    _validateIdentifier(name, 'table');
    return TableReference(name);
  }

  /// Create a column reference
  static ColumnReference column(String name, {TableReference? table}) {
    _validateIdentifier(name, 'column');
    return ColumnReference(name, table: table);
  }

  /// Create a column reference with aggregate function
  static ColumnReference count(
    String name, {
    TableReference? table,
    bool distinct = false,
  }) {
    _validateIdentifier(name, 'column');
    return ColumnReference(
      name,
      table: table,
      aggregateFunction: AggregateFunction.count,
      isDistinct: distinct,
    );
  }

  /// Create COUNT(*) reference
  static ColumnReference countAll({bool distinct = false}) {
    return ColumnReference(
      '*',
      aggregateFunction: AggregateFunction.count,
      isDistinct: distinct,
    );
  }

  /// Create SUM column reference
  static ColumnReference sum(
    String name, {
    TableReference? table,
    bool distinct = false,
  }) {
    _validateIdentifier(name, 'column');
    return ColumnReference(
      name,
      table: table,
      aggregateFunction: AggregateFunction.sum,
      isDistinct: distinct,
    );
  }

  /// Create AVG column reference
  static ColumnReference avg(
    String name, {
    TableReference? table,
    bool distinct = false,
  }) {
    _validateIdentifier(name, 'column');
    return ColumnReference(
      name,
      table: table,
      aggregateFunction: AggregateFunction.avg,
      isDistinct: distinct,
    );
  }

  /// Create MIN column reference
  static ColumnReference min(String name, {TableReference? table}) {
    _validateIdentifier(name, 'column');
    return ColumnReference(
      name,
      table: table,
      aggregateFunction: AggregateFunction.min,
    );
  }

  /// Create MAX column reference
  static ColumnReference max(String name, {TableReference? table}) {
    _validateIdentifier(name, 'column');
    return ColumnReference(
      name,
      table: table,
      aggregateFunction: AggregateFunction.max,
    );
  }

  /// Create GROUP_CONCAT column reference
  static ColumnReference groupConcat(
    String name, {
    TableReference? table,
    bool distinct = false,
  }) {
    _validateIdentifier(name, 'column');
    return ColumnReference(
      name,
      table: table,
      aggregateFunction: AggregateFunction.groupConcat,
      isDistinct: distinct,
    );
  }

  /// Create ORDER BY clause
  static OrderByClause orderBy(
    ColumnReference column,
    OrderDirection direction,
  ) {
    return OrderByClause(column, direction);
  }

  /// Create ASC ORDER BY clause
  static OrderByClause asc(ColumnReference column) {
    return OrderByClause(column, OrderDirection.asc);
  }

  /// Create DESC ORDER BY clause
  static OrderByClause desc(ColumnReference column) {
    return OrderByClause(column, OrderDirection.desc);
  }

  /// Create JOIN condition
  static JoinCondition on(ColumnReference left, ColumnReference right) {
    return JoinCondition.on(left, right);
  }

  /// Create JOIN condition with custom operator
  static JoinCondition onWith(
    ColumnReference left,
    ColumnReference right,
    ComparisonOperator operator,
  ) {
    return JoinCondition.onWith(left, right, operator);
  }
}

/// Global validation function for identifiers
void _validateIdentifier(String identifier, String type) {
  if (identifier.isEmpty) {
    throw SqlBuilderException('$type name cannot be empty');
  }

  // Allow * for special cases like COUNT(*)
  if (identifier == '*') return;

  // Validate identifier pattern
  final RegExp identifierPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
  if (!identifierPattern.hasMatch(identifier)) {
    throw SqlBuilderException(
      'Invalid $type name: $identifier. Must contain only letters, numbers, and underscores, and start with a letter or underscore',
    );
  }

  // Check for SQL keywords
  if (_isSqlKeyword(identifier)) {
    throw SqlBuilderException(
      '$type name cannot be a SQL keyword: $identifier',
    );
  }

  // Check length limits
  if (identifier.length > 63) {
    throw SqlBuilderException(
      '$type name cannot exceed 63 characters: $identifier',
    );
  }
}

/// Check if a word is a SQL keyword
bool _isSqlKeyword(String word) {
  const keywords = {
    'SELECT',
    'FROM',
    'WHERE',
    'JOIN',
    'INNER',
    'LEFT',
    'RIGHT',
    'FULL',
    'OUTER',
    'CROSS',
    'ON',
    'GROUP',
    'BY',
    'HAVING',
    'ORDER',
    'LIMIT',
    'OFFSET',
    'AS',
    'AND',
    'OR',
    'NOT',
    'NULL',
    'IS',
    'IN',
    'BETWEEN',
    'LIKE',
    'ILIKE',
    'EXISTS',
    'UNION',
    'ALL',
    'DISTINCT',
    'COUNT',
    'SUM',
    'AVG',
    'MIN',
    'MAX',
    'INSERT',
    'UPDATE',
    'DELETE',
    'CREATE',
    'DROP',
    'ALTER',
    'TABLE',
    'DATABASE',
    'INDEX',
    'VIEW',
    'TRIGGER',
    'PROCEDURE',
    'FUNCTION',
    'CASE',
    'WHEN',
    'THEN',
    'ELSE',
    'END',
    'IF',
    'WHILE',
    'FOR',
    'LOOP',
    'BREAK',
    'CONTINUE',
    'RETURN',
    'DECLARE',
    'SET',
    'BEGIN',
    'COMMIT',
    'ROLLBACK',
    'TRANSACTION',
    'SAVEPOINT',
    'RELEASE',
    'CONSTRAINT',
    'PRIMARY',
    'KEY',
    'FOREIGN',
    'REFERENCES',
    'UNIQUE',
    'CHECK',
    'DEFAULT',
    'AUTO_INCREMENT',
    'IDENTITY',
    'SEQUENCE',
    'NEXTVAL',
    'CURRVAL',
  };

  return keywords.contains(word.toUpperCase());
}

/// Extension methods for more fluent API
extension SqlBuilderExtensions on SqlBuilder {
  /// Add an AND WHERE condition
  SqlBuilder andWhere(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    _whereClause.and(column, operator, value);
    return this;
  }

  /// Add an OR WHERE condition
  SqlBuilder orWhere(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    _whereClause.or(column, operator, value);
    return this;
  }

  /// Add an AND HAVING condition
  SqlBuilder andHaving(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    _havingClause.and(column, operator, value);
    return this;
  }

  /// Add an OR HAVING condition
  SqlBuilder orHaving(
    ColumnReference column,
    ComparisonOperator operator,
    dynamic value,
  ) {
    _havingClause.or(column, operator, value);
    return this;
  }
}

/// Extension methods for TableReference
extension TableReferenceExtensions on TableReference {
  /// Create a column reference for this table
  ColumnReference operator [](String columnName) {
    return ColumnReference(columnName, table: this);
  }

  /// Create a column reference with dot notation
  ColumnReference col(String columnName) {
    return ColumnReference(columnName, table: this);
  }
}

/// Extension methods for ColumnReference
extension ColumnReferenceExtensions on ColumnReference {
  /// Create equality condition
  WhereCondition eq(dynamic value) {
    return WhereCondition(this, ComparisonOperator.equals, value);
  }

  /// Create not equals condition
  WhereCondition neq(dynamic value) {
    return WhereCondition(this, ComparisonOperator.notEquals, value);
  }

  /// Create greater than condition
  WhereCondition gt(dynamic value) {
    return WhereCondition(this, ComparisonOperator.greaterThan, value);
  }

  /// Create greater than or equal condition
  WhereCondition gte(dynamic value) {
    return WhereCondition(this, ComparisonOperator.greaterThanOrEqual, value);
  }

  /// Create less than condition
  WhereCondition lt(dynamic value) {
    return WhereCondition(this, ComparisonOperator.lessThan, value);
  }

  /// Create less than or equal condition
  WhereCondition lte(dynamic value) {
    return WhereCondition(this, ComparisonOperator.lessThanOrEqual, value);
  }

  /// Create LIKE condition
  WhereCondition like(String pattern) {
    return WhereCondition(this, ComparisonOperator.like, pattern);
  }

  /// Create NOT LIKE condition
  WhereCondition notLike(String pattern) {
    return WhereCondition(this, ComparisonOperator.notLike, pattern);
  }

  /// Create ILIKE condition (case-insensitive)
  WhereCondition iLike(String pattern) {
    return WhereCondition(this, ComparisonOperator.iLike, pattern);
  }

  /// Create IN condition
  WhereCondition inList(List values) {
    return WhereCondition(this, ComparisonOperator.inList, values);
  }

  /// Create NOT IN condition
  WhereCondition notInList(List values) {
    return WhereCondition(this, ComparisonOperator.notInList, values);
  }

  /// Create BETWEEN condition
  WhereCondition between(dynamic start, dynamic end) {
    return WhereCondition(this, ComparisonOperator.between, [start, end]);
  }

  /// Create NOT BETWEEN condition
  WhereCondition notBetween(dynamic start, dynamic end) {
    return WhereCondition(this, ComparisonOperator.notBetween, [start, end]);
  }

  /// Create IS NULL condition
  WhereCondition get isNull {
    return WhereCondition(this, ComparisonOperator.isNull, null);
  }

  /// Create IS NOT NULL condition
  WhereCondition get isNotNull {
    return WhereCondition(this, ComparisonOperator.isNotNull, null);
  }

  /// Create ASC order
  OrderByClause get asc {
    return OrderByClause(this, OrderDirection.asc);
  }

  /// Create DESC order
  OrderByClause get desc {
    return OrderByClause(this, OrderDirection.desc);
  }
}

/// Query result builder for type-safe query execution
class QueryResult {
  final String sql;
  final Map<String, dynamic> parameters;

  const QueryResult(this.sql, this.parameters);

  @override
  String toString() => 'QueryResult(sql: $sql, parameters: $parameters)';
}

/// Extension to build query result
extension SqlBuilderResult on SqlBuilder {
  /// Build query result with SQL and parameters
  QueryResult buildResult() {
    return QueryResult(build(), getParameterValues());
  }
}
