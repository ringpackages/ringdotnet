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
		}

		private sealed class Table
		{
			public string Name;
			public List<Column> Columns = new List<Column>();
			public Column KeyColumn;
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
					table.Columns.Add(column);
					if (column.Key) table.KeyColumn = column;
				}
				if (table.KeyColumn == null)
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
						builder.IndexerProperty(column.Type, column.Name);
					}
					builder.HasKey(table.KeyColumn.Name);
					if (table.KeyColumn.Type == typeof(int) || table.KeyColumn.Type == typeof(long))
					{
						builder.Property(table.KeyColumn.Name).ValueGeneratedOnAdd();
					}
				});
			}
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
			if (AutoSave) SaveChanges();
		}

		/* Add a row: returns its key (generated for int/long keys) */
		public object Insert(string entity, object[] pairs)
		{
			Table table = Find(entity);
			Dictionary<string, object> row = new Dictionary<string, object>();
			Fill(table, row, pairs);
			SetOf(table).Add(row);
			SaveIfAuto();
			return AutoSave ? row[table.KeyColumn.Name] : null;
		}

		/* The row with the key, or null */
		public List<object> GetRow(string entity, object key)
		{
			Table table = Find(entity);
			Dictionary<string, object> row = SetOf(table).Find(Coerce(key, table.KeyColumn.Type));
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
			Dictionary<string, object> row = SetOf(table).Find(Coerce(key, table.KeyColumn.Type));
			if (row == null) return false;
			Fill(table, row, pairs);
			SaveIfAuto();
			return true;
		}

		public bool Delete(string entity, object key)
		{
			Table table = Find(entity);
			Dictionary<string, object> row = SetOf(table).Find(Coerce(key, table.KeyColumn.Type));
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

		public void Save()
		{
			SaveChanges();
		}

		/* Dispose the context and release the database file (SQLite keeps pooled connections open) */
		public void Close()
		{
			Dispose();
			Microsoft.Data.Sqlite.SqliteConnection.ClearAllPools();
		}
	}
}
