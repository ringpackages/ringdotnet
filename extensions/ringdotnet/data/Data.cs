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
			RingDb db = new RingDb { connection = connection };
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
			if (connection.IndexOf(":memory:", StringComparison.OrdinalIgnoreCase) >= 0)
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
			options.UseSqlite(connection);
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
			if (type == typeof(byte[])) return value is byte[] ? value : System.Text.Encoding.Latin1.GetBytes(Convert.ToString(value, CultureInfo.InvariantCulture));
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
			return Database.ExecuteSqlRaw(sql, parameters);
		}

		/* The first value of the first row of a SQL query */
		public object Scalar(string sql)
		{
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
