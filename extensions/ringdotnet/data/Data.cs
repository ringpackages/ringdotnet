/*
**  RingDotNet.Data - Entity Framework Core for Ring programs.
**
**  A Ring program cannot declare .NET classes, so the model is described with data (tables and columns) and the entities
**  are EF Core "shared-type entities" (property bag dictionaries). Rows go to Ring as lists of [name, value] pairs.
*/

using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Linq.Expressions;
using System.Reflection;
using Microsoft.EntityFrameworkCore;

namespace RingDotNet
{
	public sealed class RingDb : DbContext
	{
		private sealed class Column
		{
			public string Name;
			public Type Type;
			public bool Key;
			public bool Nullable;
			public bool Required;
			public bool Unique;
			public bool Index;
			public int MaxLength;
			public object Default;
			public bool HasDefault;
			public string References;
			public DeleteBehavior OnDelete = DeleteBehavior.Restrict;
		}

		private sealed class Table
		{
			public string Name;
			public List<Column> Columns = new List<Column>();
			public List<Column> Keys = new List<Column>();
			public Column KeyColumn { get { return Keys[0]; } }
		}

		private sealed class SchemaCacheKeyFactory : Microsoft.EntityFrameworkCore.Infrastructure.IModelCacheKeyFactory
		{
			public object Create(DbContext context, bool designTime)
			{
				return ((RingDb)context).SchemaKey + "|" + designTime;
			}
		}

		internal string SchemaKey = "";
		private string provider = "sqlite";

		private bool IsSqlite { get { return provider == "sqlite"; } }

		private void RequireSqlite(string what)
		{
			if (!IsSqlite) throw new NotSupportedException(what + " needs the sqlite provider (this database uses " + provider + ")");
		}
		private readonly List<Table> tables = new List<Table>();
		private string connection;

		public bool AutoSave = true;

		private RingDb() { }

		/*
		**  connection: a SQLite connection string, "Data Source=people.db" or "Data Source=:memory:"
		**  schema:     [ [table, [ [column, type, isKey], ... ]], ... ]   types: int long double decimal string bool datetime bytes
		*/
		public static RingDb Create(string connection, object[] schema)
		{
			return CreateWith("sqlite", connection, schema);
		}

		/* provider: sqlite, inmemory, sqlserver, postgres, mysql (the last three need their EF Core provider package next to the other DLLs) */
		public static RingDb CreateWith(string provider, string connection, object[] schema)
		{
			provider = string.IsNullOrEmpty(provider) ? "sqlite" : provider.ToLowerInvariant();
			RingDb db = new RingDb { connection = connection, provider = provider, SchemaKey = provider + "|" + Describe(schema) };
			foreach (object item in schema)
			{
				object[] def = (object[])item;
				Table table = new Table { Name = (string)def[0] };
				foreach (object c in (object[])def[1])
				{
					object[] col = (object[])c;
					Column column = new Column { Name = (string)col[0], Type = ClrType((string)col[1]), Key = col.Length > 2 && Convert.ToDouble(col[2], CultureInfo.InvariantCulture) != 0 };
					if (col.Length > 3) ReadOptions(column, (object[])col[3]);
					table.Columns.Add(column);
					if (column.Key) table.Keys.Add(column);
				}
				if (table.Keys.Count == 0)
				{
					throw new ArgumentException("The table " + table.Name + " needs a key column");
				}
				db.tables.Add(table);
			}
			if (db.IsSqlite && connection.IndexOf(":memory:", StringComparison.OrdinalIgnoreCase) >= 0)
			{
				/* an in-memory database lives as long as its connection: keep it open */
				db.Database.OpenConnection();
			}
			db.Database.EnsureCreated();
			return db;
		}

		/* options: [ [name, value], ... ] with required, nullable, unique, index, maxlength, default */
		private static void ReadOptions(Column column, object[] options)
		{
			foreach (object o in options)
			{
				object[] pair = (object[])o;
				string name = ((string)pair[0]).ToLowerInvariant();
				object value = pair[1];
				bool flag = !(value is double) || Convert.ToDouble(value, CultureInfo.InvariantCulture) != 0;
				switch (name)
				{
					case "required": column.Required = flag; break;
					case "nullable": column.Nullable = flag; break;
					case "unique": column.Unique = flag; break;
					case "index": column.Index = flag; break;
					case "maxlength": column.MaxLength = Convert.ToInt32(value, CultureInfo.InvariantCulture); break;
					case "default": column.Default = value; column.HasDefault = true; break;
					case "references": column.References = (string)value; break;
					case "ondelete": column.OnDelete = ParseDelete((string)value); break;
					default: throw new ArgumentException("Unknown column option: " + name);
				}
			}
			if (column.Nullable && column.Type.IsValueType) column.Type = typeof(Nullable<>).MakeGenericType(column.Type);
		}

		private static DeleteBehavior ParseDelete(string name)
		{
			switch (name.ToLowerInvariant())
			{
				case "cascade": return DeleteBehavior.Cascade;
				case "restrict": return DeleteBehavior.Restrict;
				case "setnull": return DeleteBehavior.SetNull;
				case "noaction": return DeleteBehavior.NoAction;
				default: throw new ArgumentException("Unknown ondelete: " + name + " (cascade, restrict, setnull, noaction)");
			}
		}

		private void UseProvider(DbContextOptionsBuilder options)
		{
			switch (provider)
			{
				case "sqlite": options.UseSqlite(connection); return;
				case "inmemory": options.UseInMemoryDatabase(connection); return;
				case "sqlserver": UseByName(options, "Microsoft.EntityFrameworkCore.SqlServer", "Microsoft.EntityFrameworkCore.SqlServerDbContextOptionsExtensions", "UseSqlServer"); return;
				case "postgres": UseByName(options, "Npgsql.EntityFrameworkCore.PostgreSQL", "Microsoft.EntityFrameworkCore.NpgsqlDbContextOptionsBuilderExtensions", "UseNpgsql"); return;
				case "mysql": UseByName(options, "Pomelo.EntityFrameworkCore.MySql", "Microsoft.EntityFrameworkCore.MySqlDbContextOptionsExtensions", "UseMySql"); return;
				default: throw new ArgumentException("Unknown provider: " + provider + " (sqlite, inmemory, sqlserver, postgres, mysql)");
			}
		}

		/* a provider whose package is not bundled: call its UseXxx(options, connection) extension method by reflection */
		private void UseByName(DbContextOptionsBuilder options, string assemblyName, string typeName, string methodName)
		{
			System.Reflection.Assembly assembly;
			try { assembly = System.Reflection.Assembly.Load(assemblyName); }
			catch (Exception e) { throw new InvalidOperationException("The provider " + provider + " needs the package " + assemblyName + " (copy its DLLs next to RingDotNet.Data.dll): " + e.Message); }
			Type type = assembly.GetType(typeName, true);
			foreach (System.Reflection.MethodInfo method in type.GetMethods())
			{
				System.Reflection.ParameterInfo[] ps = method.GetParameters();
				if (method.Name != methodName || ps.Length < 2 || ps[0].ParameterType != typeof(DbContextOptionsBuilder) || ps[1].ParameterType != typeof(string)) continue;
				bool simple = true;
				object[] args = new object[ps.Length];
				args[0] = options;
				args[1] = connection;
				for (int i = 2; i < ps.Length; i++)
				{
					if (ps[i].IsOptional) args[i] = Type.Missing;
					else if (ps[i].ParameterType.Name == "ServerVersion") args[i] = ps[i].ParameterType.GetMethod("AutoDetect", new[] { typeof(string) }).Invoke(null, new object[] { connection });
					else simple = false;
				}
				if (!simple) continue;
				method.Invoke(null, args);
				return;
			}
			throw new InvalidOperationException("No " + methodName + "(options, connection) method in " + typeName);
		}

		private static string Describe(object[] items)
		{
			System.Text.StringBuilder text = new System.Text.StringBuilder();
			foreach (object item in items)
			{
				if (item is object[] list) { text.Append('['); text.Append(Describe(list)); text.Append(']'); }
				else if (item is List<object> l) { text.Append('['); text.Append(Describe(l.ToArray())); text.Append(']'); }
				else text.Append(Convert.ToString(item, CultureInfo.InvariantCulture)).Append(',');
			}
			return text.ToString();
		}

		private static Type ClrType(string name)
		{
			switch (name.ToLowerInvariant())
			{
				case "int": return typeof(int);
				case "long": return typeof(long);
				case "double": return typeof(double);
				case "decimal": return typeof(decimal);
				case "string": case "text": return typeof(string);
				case "bool": return typeof(bool);
				case "datetime": return typeof(DateTime);
				case "bytes": return typeof(byte[]);
				default: throw new ArgumentException("Unknown column type: " + name);
			}
		}

		protected override void OnConfiguring(DbContextOptionsBuilder options)
		{
			UseProvider(options);
			/* the model depends on the schema: do not share the cached model between contexts with different schemas */
			options.ReplaceService<Microsoft.EntityFrameworkCore.Infrastructure.IModelCacheKeyFactory, SchemaCacheKeyFactory>();
		}

		protected override void OnModelCreating(ModelBuilder modelBuilder)
		{
			foreach (Table table in tables)
			{
				modelBuilder.SharedTypeEntity<Dictionary<string, object>>(table.Name, builder =>
				{
					builder.ToTable(table.Name);
					foreach (Column column in table.Columns)
					{
						var property = builder.IndexerProperty(column.Type, column.Name);
						if (column.Required) property.IsRequired();
						if (column.MaxLength > 0) property.HasMaxLength(column.MaxLength);
						if (column.HasDefault) property.HasDefaultValue(Coerce(column.Default, column.Type));
						if (column.Unique) builder.HasIndex(column.Name).IsUnique();
						else if (column.Index) builder.HasIndex(column.Name);
					}
					builder.HasKey(table.Keys.Select(k => k.Name).ToArray());
					if (table.Keys.Count == 1 && (table.KeyColumn.Type == typeof(int) || table.KeyColumn.Type == typeof(long)))
					{
						builder.Property(table.KeyColumn.Name).ValueGeneratedOnAdd();
					}
					else
					{
						foreach (Column key in table.Keys) builder.Property(key.Name).ValueGeneratedNever();
					}
				});
			}
			/* the relationships: a column that references the key of another table */
			foreach (Table table in tables)
			{
				foreach (Column column in table.Columns)
				{
					if (column.References == null) continue;
					Table principal = Find(column.References);
					modelBuilder.SharedTypeEntity<Dictionary<string, object>>(table.Name, builder =>
					{
						builder.HasOne(principal.Name, (string)null).WithMany((string)null).HasForeignKey(column.Name).OnDelete(column.OnDelete);
					});
				}
			}
		}

		/* the key of a row: one value, or a list of values for a composite key */
		private object[] KeyValues(Table table, object key)
		{
			object[] values = key as object[] ?? new object[] { key };
			if (values.Length != table.Keys.Count) throw new ArgumentException("The table " + table.Name + " has a key of " + table.Keys.Count + " column(s)");
			object[] result = new object[values.Length];
			for (int i = 0; i < values.Length; i++) result[i] = Coerce(values[i], table.Keys[i].Type);
			return result;
		}

		private Table Find(string entity)
		{
			foreach (Table t in tables)
			{
				if (string.Equals(t.Name, entity, StringComparison.OrdinalIgnoreCase)) return t;
			}
			throw new ArgumentException("Unknown table: " + entity);
		}

		private DbSet<Dictionary<string, object>> SetOf(Table table)
		{
			return Set<Dictionary<string, object>>(table.Name);
		}

		private static object Coerce(object value, Type type)
		{
			if (value == null) return null;
			type = Nullable.GetUnderlyingType(type) ?? type;
			if (type == typeof(DateTime)) return value is DateTime ? value : DateTime.Parse(Convert.ToString(value, CultureInfo.InvariantCulture), CultureInfo.InvariantCulture);
			if (type == typeof(byte[])) return value is byte[] ? value : Convert.FromHexString(Convert.ToString(value, CultureInfo.InvariantCulture));
			if (type == typeof(bool)) return value is bool ? value : Convert.ToDouble(value, CultureInfo.InvariantCulture) != 0;
			return Convert.ChangeType(value, type, CultureInfo.InvariantCulture);
		}

		private void Fill(Table table, Dictionary<string, object> row, object[] pairs)
		{
			foreach (object p in pairs)
			{
				object[] pair = (object[])p;
				string name = (string)pair[0];
				Column column = table.Columns.Find(c => string.Equals(c.Name, name, StringComparison.OrdinalIgnoreCase));
				if (column == null) throw new ArgumentException("Unknown column " + name + " in " + table.Name);
				row[column.Name] = Coerce(pair[1], column.Type);
			}
		}

		private List<object> ToPairs(Table table, Dictionary<string, object> row)
		{
			List<object> pairs = new List<object>();
			foreach (Column column in table.Columns)
			{
				object value = row.TryGetValue(column.Name, out object v) ? v : null;
				if (value is DateTime date) value = date.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
				else if (value is byte[] bytes) value = Convert.ToHexString(bytes).ToLowerInvariant();
				pairs.Add(new List<object> { column.Name, value });
			}
			return pairs;
		}

		private List<object> Rows(Table table, IEnumerable<Dictionary<string, object>> rows)
		{
			List<object> list = new List<object>();
			foreach (Dictionary<string, object> row in rows) list.Add(ToPairs(table, row));
			return list;
		}

		private void SaveIfAuto()
		{
			if (!AutoSave) return;
			try
			{
				SaveChanges();
			}
			catch
			{
				/* forget the changes that could not be saved: the next call starts clean */
				ChangeTracker.Clear();
				throw;
			}
		}

		/* Forget the changes that were not saved */
		public void Discard()
		{
			ChangeTracker.Clear();
		}

		/* The description of a column: [ [name, value], ... ] */
		public List<object> ColumnInfo(string entity, string column)
		{
			Table table = Find(entity);
			Column c = table.Columns.Find(x => string.Equals(x.Name, column, StringComparison.OrdinalIgnoreCase));
			if (c == null) throw new ArgumentException("Unknown column " + column + " in " + table.Name);
			return new List<object> {
				new List<object> { "name", c.Name }, new List<object> { "type", (Nullable.GetUnderlyingType(c.Type) ?? c.Type).Name },
				new List<object> { "key", c.Key ? 1 : 0 }, new List<object> { "nullable", c.Nullable ? 1 : 0 },
				new List<object> { "required", c.Required ? 1 : 0 }, new List<object> { "unique", c.Unique ? 1 : 0 },
				new List<object> { "index", c.Index ? 1 : 0 }, new List<object> { "maxlength", c.MaxLength } };
		}

		/* Add a row: returns its key (generated for int/long keys) */
		public object Insert(string entity, object[] pairs)
		{
			Table table = Find(entity);
			Dictionary<string, object> row = new Dictionary<string, object>();
			Fill(table, row, pairs);
			SetOf(table).Add(row);
			SaveIfAuto();
			if (!AutoSave) return null;
			if (table.Keys.Count == 1) return row[table.KeyColumn.Name];
			return table.Keys.Select(k => row[k.Name]).ToList();
		}

		/* The row with the key, or null */
		public List<object> GetRow(string entity, object key)
		{
			Table table = Find(entity);
			Dictionary<string, object> row = SetOf(table).Find(KeyValues(table, key));
			return row == null ? null : ToPairs(table, row);
		}

		public List<object> All(string entity)
		{
			Table table = Find(entity);
			return Rows(table, SetOf(table).AsNoTracking().ToList());
		}

		/* Rows that match a SQL condition: Where("Customers", "Age > {0} AND City = {1}", [30, "Cairo"]) */
		public List<object> Where(string entity, string condition, object[] parameters)
		{
			RequireSqlite("Where with a SQL condition");
			Table table = Find(entity);
			string sql = "SELECT * FROM \"" + table.Name + "\" WHERE " + condition;
			return Rows(table, SetOf(table).FromSqlRaw(sql, parameters).AsNoTracking().ToList());
		}

		public bool Update(string entity, object key, object[] pairs)
		{
			Table table = Find(entity);
			Dictionary<string, object> row = SetOf(table).Find(KeyValues(table, key));
			if (row == null) return false;
			Fill(table, row, pairs);
			SaveIfAuto();
			return true;
		}

		public bool Delete(string entity, object key)
		{
			Table table = Find(entity);
			Dictionary<string, object> row = SetOf(table).Find(KeyValues(table, key));
			if (row == null) return false;
			SetOf(table).Remove(row);
			SaveIfAuto();
			return true;
		}

		public long Count(string entity)
		{
			Table table = Find(entity);
			return SetOf(table).LongCount();
		}

		/* A SQL statement that changes data: returns the number of rows */
		public int Execute(string sql, object[] parameters)
		{
			if (provider == "inmemory") throw new NotSupportedException("The inmemory provider cannot run SQL");
			return Database.ExecuteSqlRaw(sql, parameters);
		}

		/* The first value of the first row of a SQL query */
		public object Scalar(string sql)
		{
			if (provider == "inmemory") throw new NotSupportedException("The inmemory provider cannot run SQL");
			DbConnection connection = Database.GetDbConnection();
			bool wasClosed = connection.State != System.Data.ConnectionState.Open;
			if (wasClosed) connection.Open();
			try
			{
				using (DbCommand command = connection.CreateCommand())
				{
					command.CommandText = sql;
					object value = command.ExecuteScalar();
					return value == DBNull.Value ? null : value;
				}
			}
			finally
			{
				if (wasClosed) connection.Close();
			}
		}

		private static Column ForeignKeyTo(Table child, Table parent)
		{
			foreach (Column c in child.Columns)
			{
				if (c.References != null && string.Equals(c.References, parent.Name, StringComparison.OrdinalIgnoreCase)) return c;
			}
			return null;
		}

		/* The rows of childEntity that belong to the row of parentEntity with this key */
		public List<object> Children(string parentEntity, object key, string childEntity)
		{
			Table parent = Find(parentEntity);
			Table child = Find(childEntity);
			Column fk = ForeignKeyTo(child, parent);
			if (fk == null) throw new ArgumentException(child.Name + " has no column that references " + parent.Name);
			string sql = "SELECT * FROM \"" + child.Name + "\" WHERE \"" + fk.Name + "\" = {0}";
			return Rows(child, SetOf(child).FromSqlRaw(sql, KeyValues(parent, key)[0]).AsNoTracking().ToList());
		}

		/* The row of parentEntity that the row of childEntity with this key belongs to, or null */
		public List<object> Parent(string childEntity, object key, string parentEntity)
		{
			Table parent = Find(parentEntity);
			Table child = Find(childEntity);
			Column fk = ForeignKeyTo(child, parent);
			if (fk == null) throw new ArgumentException(child.Name + " has no column that references " + parent.Name);
			Dictionary<string, object> row = SetOf(child).Find(KeyValues(child, key));
			if (row == null || !row.TryGetValue(fk.Name, out object value) || value == null) return null;
			Dictionary<string, object> found = SetOf(parent).Find(Coerce(value, parent.KeyColumn.Type));
			return found == null ? null : ToPairs(parent, found);
		}

		/* All the rows of entity with their related rows (two queries): [ [row, related], ... ]
		   related is the list of child rows when relatedEntity references entity, or the parent row (or null) when entity references relatedEntity */
		public List<object> Include(string entity, string relatedEntity)
		{
			Table table = Find(entity);
			Table related = Find(relatedEntity);
			List<Dictionary<string, object>> rows = SetOf(table).AsNoTracking().ToList();
			List<Dictionary<string, object>> others = SetOf(related).AsNoTracking().ToList();
			List<object> result = new List<object>();
			Column down = ForeignKeyTo(related, table);
			Column up = ForeignKeyTo(table, related);
			if (down == null && up == null) throw new ArgumentException(table.Name + " and " + related.Name + " are not related");
			foreach (Dictionary<string, object> row in rows)
			{
				object link;
				if (down != null)
				{
					object id = row[table.KeyColumn.Name];
					List<object> children = new List<object>();
					foreach (Dictionary<string, object> other in others)
					{
						if (other.TryGetValue(down.Name, out link) && link != null && Convert.ToString(link, CultureInfo.InvariantCulture) == Convert.ToString(id, CultureInfo.InvariantCulture)) children.Add(ToPairs(related, other));
					}
					result.Add(new List<object> { ToPairs(table, row), children });
				}
				else
				{
					List<object> parentRow = null;
					if (row.TryGetValue(up.Name, out link) && link != null)
					{
						foreach (Dictionary<string, object> other in others)
						{
							if (Convert.ToString(other[related.KeyColumn.Name], CultureInfo.InvariantCulture) == Convert.ToString(link, CultureInfo.InvariantCulture)) { parentRow = ToPairs(related, other); break; }
						}
					}
					result.Add(new List<object> { ToPairs(table, row), parentRow });
				}
			}
			return result;
		}

		private Microsoft.EntityFrameworkCore.Storage.IDbContextTransaction transaction;

		/* Start a transaction: the changes are saved when Commit is called, or undone by Rollback */
		public void Begin()
		{
			if (transaction != null) throw new InvalidOperationException("A transaction is already active");
			transaction = Database.BeginTransaction();
		}

		public void Commit()
		{
			if (transaction == null) throw new InvalidOperationException("There is no active transaction");
			try
			{
				SaveChanges();
				transaction.Commit();
			}
			catch
			{
				ChangeTracker.Clear();
				transaction.Rollback();
				throw;
			}
			finally
			{
				transaction.Dispose();
				transaction = null;
			}
		}

		public void Rollback()
		{
			if (transaction == null) throw new InvalidOperationException("There is no active transaction");
			ChangeTracker.Clear();
			try
			{
				transaction.Rollback();
			}
			finally
			{
				transaction.Dispose();
				transaction = null;
			}
		}

		public bool InTransaction { get { return transaction != null; } }

		/* Async versions: they return a Task, call Wait() and read Result in Ring */
		public System.Threading.Tasks.Task<object> InsertAsync(string entity, object[] pairs)
		{
			return System.Threading.Tasks.Task.Run(() => Insert(entity, pairs));
		}

		public System.Threading.Tasks.Task<List<object>> AllAsync(string entity)
		{
			Table table = Find(entity);
			return SetOf(table).AsNoTracking().ToListAsync().ContinueWith(t => Rows(table, t.Result));
		}

		public System.Threading.Tasks.Task<List<object>> WhereAsync(string entity, string condition, object[] parameters)
		{
			Table table = Find(entity);
			string sql = "SELECT * FROM \"" + table.Name + "\" WHERE " + condition;
			return SetOf(table).FromSqlRaw(sql, parameters).AsNoTracking().ToListAsync().ContinueWith(t => Rows(table, t.Result));
		}

		public System.Threading.Tasks.Task<long> CountAsync(string entity)
		{
			return SetOf(Find(entity)).LongCountAsync();
		}

		public System.Threading.Tasks.Task<int> SaveAsync()
		{
			return SaveChangesAsync();
		}

		private List<string> Names(string sql)
		{
			return Database.SqlQueryRaw<string>(sql).ToList();
		}

		private static string SqlType(Type type)
		{
			type = Nullable.GetUnderlyingType(type) ?? type;
			if (type == typeof(int) || type == typeof(long) || type == typeof(bool)) return "INTEGER";
			if (type == typeof(double)) return "REAL";
			if (type == typeof(byte[])) return "BLOB";
			return "TEXT";
		}

		private static string SqlLiteral(object value, Type type)
		{
			value = Coerce(value, type);
			if (value is bool b) return b ? "1" : "0";
			if (value is string || value is DateTime) return "'" + Convert.ToString(value, CultureInfo.InvariantCulture).Replace("'", "''") + "'";
			return Convert.ToString(value, CultureInfo.InvariantCulture);
		}

		/*
		**  Bring an existing database in line with the model: creates the missing tables, adds the missing columns and indexes.
		**  Returns the list of changes. (Columns are never dropped or changed: use Execute for that.)
		*/
		public List<object> Migrate()
		{
			RequireSqlite("Migrate");
			List<object> changes = new List<object>();
			List<string> existingTables = Names("SELECT name AS Value FROM sqlite_master WHERE type = 'table'");
			string script = Database.GenerateCreateScript();
			List<string> statements = script.Split(';').Select(x => x.Trim()).Where(x => x.Length > 0).ToList();
			foreach (Table table in tables)
			{
				if (!existingTables.Any(n => string.Equals(n, table.Name, StringComparison.OrdinalIgnoreCase)))
				{
					string create = statements.FirstOrDefault(x => x.StartsWith("CREATE TABLE \"" + table.Name + "\"", StringComparison.OrdinalIgnoreCase));
					if (create == null) throw new InvalidOperationException("No create statement for " + table.Name + " in: " + script);
					Database.ExecuteSqlRaw(create.Replace("{", "{{").Replace("}", "}}"));
					changes.Add("create table " + table.Name);
					continue;
				}
				List<string> columns = Names("SELECT name AS Value FROM pragma_table_info('" + table.Name.Replace("'", "''") + "')");
				foreach (Column column in table.Columns)
				{
					if (columns.Any(n => string.Equals(n, column.Name, StringComparison.OrdinalIgnoreCase))) continue;
					string definition = "\"" + column.Name + "\" " + SqlType(column.Type);
					if (column.References != null)
					{
						Table principal = Find(column.References);
						definition += " REFERENCES \"" + principal.Name + "\" (\"" + principal.KeyColumn.Name + "\")";
					}
					else if (column.HasDefault)
					{
						definition += " DEFAULT " + SqlLiteral(column.Default, column.Type);
						if (!column.Nullable) definition += " NOT NULL";
					}
					else if (!column.Nullable && (column.Required || column.Type.IsValueType))
					{
						definition += " NOT NULL DEFAULT " + (SqlType(column.Type) == "TEXT" ? "''" : "0");
					}
					Database.ExecuteSqlRaw("ALTER TABLE \"" + table.Name + "\" ADD COLUMN " + definition);
					changes.Add("add column " + table.Name + "." + column.Name);
				}
			}
			List<string> indexes = Names("SELECT name AS Value FROM sqlite_master WHERE type = 'index'");
			foreach (string statement in statements)
			{
				Match m = Regex.Match(statement, "^CREATE (UNIQUE )?INDEX \"([^\"]+)\"", RegexOptions.IgnoreCase);
				if (m.Success && !indexes.Contains(m.Groups[2].Value))
				{
					Database.ExecuteSqlRaw(statement.Replace("{", "{{").Replace("}", "}}"));
					changes.Add("create index " + m.Groups[2].Value);
				}
			}
			return changes;
		}

		/*
		**  A named change that is applied once (the names are kept in the table RingMigrations): Apply("001-prices", "UPDATE ...")
		**  returns true when it was applied now, false when it had been applied before
		*/
		public bool Apply(string name, string sql)
		{
			RequireSqlite("Apply");
			Database.ExecuteSqlRaw("CREATE TABLE IF NOT EXISTS \"RingMigrations\" (\"Name\" TEXT NOT NULL PRIMARY KEY, \"AppliedAt\" TEXT NOT NULL)");
			if (Names("SELECT Name AS Value FROM RingMigrations").Contains(name)) return false;
			using (var tx = Database.BeginTransaction())
			{
				Database.ExecuteSqlRaw(sql.Replace("{", "{{").Replace("}", "}}"));
				Database.ExecuteSqlRaw("INSERT INTO \"RingMigrations\" (\"Name\", \"AppliedAt\") VALUES ({0}, {1})", name, DateTime.UtcNow.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture));
				tx.Commit();
			}
			return true;
		}

		/* The names of the changes applied so far */
		public List<object> Applied()
		{
			RequireSqlite("Applied");
			Database.ExecuteSqlRaw("CREATE TABLE IF NOT EXISTS \"RingMigrations\" (\"Name\" TEXT NOT NULL PRIMARY KEY, \"AppliedAt\" TEXT NOT NULL)");
			return Names("SELECT Name AS Value FROM RingMigrations ORDER BY AppliedAt, Name").Cast<object>().ToList();
		}

		// ------------------------------------------------------------------ queries built as LINQ expression trees

		private static readonly MethodInfo EfProperty = typeof(EF).GetMethod("Property");

		private static Expression PropertyOf(ParameterExpression row, Column column)
		{
			return Expression.Call(EfProperty.MakeGenericMethod(column.Type), row, Expression.Constant(column.Name));
		}

		private Column ColumnOf(Table table, object name)
		{
			string n = (string)name;
			Column c = table.Columns.Find(x => string.Equals(x.Name, n, StringComparison.OrdinalIgnoreCase));
			if (c == null) throw new ArgumentException("Unknown column " + n + " in " + table.Name);
			return c;
		}

		private static Expression Constant(object value, Type type)
		{
			return Expression.Constant(Coerce(value, type), type);
		}

		private static bool CanBeNull(Type type)
		{
			return !type.IsValueType || Nullable.GetUnderlyingType(type) != null;
		}

		/*
		**  A condition as data: [column, op, value]   op: = != < <= > >= contains startswith endswith in isnull notnull
		**                       ["and", c1, c2, ...]  ["or", c1, c2, ...]  ["not", c]
		*/
		private Expression Condition(Table table, ParameterExpression row, object[] condition)
		{
			string first = Convert.ToString(condition[0], CultureInfo.InvariantCulture);
			switch (first.ToLowerInvariant())
			{
				case "and":
				case "or":
				{
					Expression result = null;
					for (int i = 1; i < condition.Length; i++)
					{
						Expression part = Condition(table, row, (object[])condition[i]);
						result = result == null ? part : (first.ToLowerInvariant() == "and" ? Expression.AndAlso(result, part) : Expression.OrElse(result, part));
					}
					return result ?? Expression.Constant(true);
				}
				case "not":
					return Expression.Not(Condition(table, row, (object[])condition[1]));
			}
			Column column = ColumnOf(table, condition[0]);
			string op = ((string)condition[1]).ToLowerInvariant();
			Expression property = PropertyOf(row, column);
			Type type = column.Type;
			if (op == "isnull") return CanBeNull(type) ? Expression.Equal(property, Expression.Constant(null, type)) : Expression.Constant(false);
			if (op == "notnull") return CanBeNull(type) ? Expression.NotEqual(property, Expression.Constant(null, type)) : Expression.Constant(true);
			object value = condition[2];
			switch (op)
			{
				case "=": return Expression.Equal(property, Constant(value, type));
				case "!=": return Expression.NotEqual(property, Constant(value, type));
				case "<": return Expression.LessThan(property, Constant(value, type));
				case "<=": return Expression.LessThanOrEqual(property, Constant(value, type));
				case ">": return Expression.GreaterThan(property, Constant(value, type));
				case ">=": return Expression.GreaterThanOrEqual(property, Constant(value, type));
				case "contains":
				case "startswith":
				case "endswith":
				{
					string method = op == "contains" ? "Contains" : op == "startswith" ? "StartsWith" : "EndsWith";
					return Expression.Call(property, typeof(string).GetMethod(method, new[] { typeof(string) }), Expression.Constant(Convert.ToString(value, CultureInfo.InvariantCulture)));
				}
				case "in":
				{
					object[] items = (object[])value;
					Array array = Array.CreateInstance(type, items.Length);
					for (int i = 0; i < items.Length; i++) array.SetValue(Coerce(items[i], type), i);
					MethodInfo contains = typeof(Enumerable).GetMethods().First(m => m.Name == "Contains" && m.GetParameters().Length == 2).MakeGenericMethod(type);
					return Expression.Call(contains, Expression.Constant(array), property);
				}
				default: throw new ArgumentException("Unknown operator: " + op);
			}
		}

		private IQueryable<Dictionary<string, object>> Filtered(Table table, object[] condition)
		{
			IQueryable<Dictionary<string, object>> query = SetOf(table).AsNoTracking();
			if (condition != null && condition.Length > 0)
			{
				ParameterExpression row = Expression.Parameter(typeof(Dictionary<string, object>), "e");
				query = query.Where(Expression.Lambda<Func<Dictionary<string, object>, bool>>(Condition(table, row, condition), row));
			}
			return query;
		}

		private IQueryable<Dictionary<string, object>> Ordered(Table table, IQueryable<Dictionary<string, object>> query, object[] orders)
		{
			bool first = true;
			foreach (object o in orders)
			{
				object[] order = o is object[] pair ? pair : new object[] { o, "asc" };
				Column column = ColumnOf(table, order[0]);
				bool descending = order.Length > 1 && string.Equals(Convert.ToString(order[1], CultureInfo.InvariantCulture), "desc", StringComparison.OrdinalIgnoreCase);
				ParameterExpression row = Expression.Parameter(typeof(Dictionary<string, object>), "e");
				LambdaExpression key = Expression.Lambda(PropertyOf(row, column), row);
				string name = first ? (descending ? "OrderByDescending" : "OrderBy") : (descending ? "ThenByDescending" : "ThenBy");
				MethodInfo method = typeof(Queryable).GetMethods().First(m => m.Name == name && m.GetParameters().Length == 2).MakeGenericMethod(typeof(Dictionary<string, object>), column.Type);
				query = (IQueryable<Dictionary<string, object>>)method.Invoke(null, new object[] { query, key });
				first = false;
			}
			return query;
		}

		/*
		**  A query as data: [ ["where", condition], ["orderby", [ [column, "desc"], ... ]], ["skip", n], ["take", n], ["select", [columns]] ]
		**  Works with every provider (EF translates the expression tree to SQL).
		*/
		public List<object> Query(string entity, object[] spec)
		{
			Table table = Find(entity);
			object[] condition = null, orders = new object[0], select = null;
			int skip = 0, take = -1;
			foreach (object item in spec)
			{
				object[] pair = (object[])item;
				switch (((string)pair[0]).ToLowerInvariant())
				{
					case "where": condition = (object[])pair[1]; break;
					case "orderby": orders = pair[1] is object[] list ? list : new object[] { pair[1] }; break;
					case "skip": skip = Convert.ToInt32(pair[1], CultureInfo.InvariantCulture); break;
					case "take": take = Convert.ToInt32(pair[1], CultureInfo.InvariantCulture); break;
					case "select": select = (object[])pair[1]; break;
					default: throw new ArgumentException("Unknown query item: " + pair[0]);
				}
			}
			IQueryable<Dictionary<string, object>> query = Ordered(table, Filtered(table, condition), orders);
			if (skip > 0) query = query.Skip(skip);
			if (take >= 0) query = query.Take(take);
			List<object> rows = Rows(table, query.ToList());
			if (select == null) return rows;
			List<object> projected = new List<object>();
			foreach (object r in rows)
			{
				List<object> kept = new List<object>();
				foreach (object o in select)
				{
					string name = ColumnOf(table, o).Name;
					kept.Add(((List<object>)r).First(p => (string)((List<object>)p)[0] == name));
				}
				projected.Add(kept);
			}
			return projected;
		}

		/* count, sum, min, max or average of a column (the column is ignored for count) of the rows that match a condition (may be null) */
		public object Aggregate(string entity, string function, string columnName, object[] condition)
		{
			Table table = Find(entity);
			IQueryable<Dictionary<string, object>> query = Filtered(table, condition);
			string f = function.ToLowerInvariant();
			if (f == "count") return query.LongCount();
			Column column = ColumnOf(table, columnName);
			Type type = column.Type;
			ParameterExpression row = Expression.Parameter(typeof(Dictionary<string, object>), "e");
			LambdaExpression selector = Expression.Lambda(PropertyOf(row, column), row);
			MethodInfo method;
			switch (f)
			{
				case "sum":
				case "average":
					method = typeof(Queryable).GetMethods().First(m => m.Name == (f == "sum" ? "Sum" : "Average") && m.GetParameters().Length == 2 && m.GetParameters()[1].ParameterType.GetGenericArguments()[0].GetGenericArguments()[1] == type);
					return method.MakeGenericMethod(typeof(Dictionary<string, object>)).Invoke(null, new object[] { query, selector });
				case "min":
				case "max":
					method = typeof(Queryable).GetMethods().First(m => m.Name == (f == "min" ? "Min" : "Max") && m.GetParameters().Length == 2 && m.GetGenericArguments().Length == 2);
					object result = method.MakeGenericMethod(typeof(Dictionary<string, object>), type).Invoke(null, new object[] { query, selector });
					if (result is DateTime date) return date.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
					return result;
				default: throw new ArgumentException("Unknown aggregate: " + function + " (count, sum, min, max, average)");
			}
		}

		/* [ [value, count], ... ] for each value of a column, for the rows that match a condition (may be null) */
		public List<object> GroupCount(string entity, string columnName, object[] condition)
		{
			Table table = Find(entity);
			Column column = ColumnOf(table, columnName);
			List<object> result = new List<object>();
			var groups = Filtered(table, condition).ToList().GroupBy(r => r.TryGetValue(column.Name, out object v) ? v : null);
			foreach (var g in groups.OrderBy(g => Convert.ToString(g.Key, CultureInfo.InvariantCulture)))
			{
				object key = g.Key is DateTime d ? d.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture) : g.Key;
				result.Add(new List<object> { key, (long)g.Count() });
			}
			return result;
		}

		// ------------------------------------------------------------------ SQL with any result shape

		private DbCommand SqlCommand(DbConnection connection, string sql, object[] parameters)
		{
			DbCommand command = connection.CreateCommand();
			object[] values = parameters ?? new object[0];
			command.CommandText = Regex.Replace(sql, @"\{(\d+)\}", m => "@p" + m.Groups[1].Value);
			for (int i = 0; i < values.Length; i++)
			{
				DbParameter p = command.CreateParameter();
				p.ParameterName = "@p" + i;
				p.Value = values[i] ?? DBNull.Value;
				command.Parameters.Add(p);
			}
			return command;
		}

		/* The rows of any SELECT as lists of [column, value] pairs: SqlRows("SELECT City, COUNT(*) AS N FROM Customers WHERE Age > {0} GROUP BY City", [18]) */
		public List<object> SqlRows(string sql, object[] parameters)
		{
			if (provider == "inmemory") throw new NotSupportedException("The inmemory provider cannot run SQL");
			DbConnection connection = Database.GetDbConnection();
			bool wasClosed = connection.State != System.Data.ConnectionState.Open;
			if (wasClosed) connection.Open();
			try
			{
				using (DbCommand command = SqlCommand(connection, sql, parameters))
				using (DbDataReader reader = command.ExecuteReader())
				{
					List<object> rows = new List<object>();
					while (reader.Read())
					{
						List<object> row = new List<object>();
						for (int i = 0; i < reader.FieldCount; i++)
						{
							object value = reader.GetValue(i);
							if (value == DBNull.Value) value = null;
							else if (value is DateTime date) value = date.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
							else if (value is byte[] bytes) value = Convert.ToHexString(bytes).ToLowerInvariant();
							else if (value is long l && l >= int.MinValue && l <= int.MaxValue) value = (int)l;
							row.Add(new List<object> { reader.GetName(i), value });
						}
						rows.Add(row);
					}
					return rows;
				}
			}
			finally
			{
				if (wasClosed) connection.Close();
			}
		}

		public void Save()
		{
			try
			{
				SaveChanges();
			}
			catch
			{
				ChangeTracker.Clear();
				throw;
			}
		}

		/* Dispose the context and release the database file (SQLite keeps pooled connections open) */
		public void Close()
		{
			Dispose();
			Microsoft.Data.Sqlite.SqliteConnection.ClearAllPools();
		}
	}
}
