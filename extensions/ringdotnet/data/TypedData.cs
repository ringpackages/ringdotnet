/*
**  RingDotNet.Data - typed entities.
**
**  The tables of the schema become real .NET classes (made with Reflection.Emit): one property per column, a navigation property to the
**  parent for each foreign key and a collection on the parent. EF Core then works with them as with classes written in C#
**  (change tracking, Include, navigation properties).
*/

using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Linq.Expressions;
using System.Reflection;
using System.Reflection.Emit;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace RingDotNet
{
	public sealed class RingTypedDb : DbContext
	{
		private sealed class Navigation
		{
			public RingDb.Table Child;
			public RingDb.Column Column;
			public RingDb.Table Parent;
			public string ReferenceName;	/* on the child: the parent entity */
			public string CollectionName;	/* on the parent: the child entities */
		}

		private sealed class SchemaCacheKeyFactory : Microsoft.EntityFrameworkCore.Infrastructure.IModelCacheKeyFactory
		{
			public object Create(DbContext context, bool designTime)
			{
				return ((RingTypedDb)context).schemaKey + "|" + designTime;
			}
		}

		private static int counter;
		private readonly List<RingDb.Table> tables = new List<RingDb.Table>();
		private readonly Dictionary<string, Type> types = new Dictionary<string, Type>(StringComparer.OrdinalIgnoreCase);
		private readonly List<Navigation> navigations = new List<Navigation>();
		private string schemaKey = "";
		private string provider = "sqlite";
		private string connection;
		public bool AutoSave = true;
		private Microsoft.EntityFrameworkCore.Storage.IDbContextTransaction transaction;

		private RingTypedDb() { }

		public static RingTypedDb Create(string provider, string connection, object[] schema)
		{
			provider = string.IsNullOrEmpty(provider) ? "sqlite" : provider.ToLowerInvariant();
			RingTypedDb db = new RingTypedDb { provider = provider, connection = connection };
			db.tables.AddRange(RingDb.ParseSchema(schema));
			db.schemaKey = "typed|" + provider + "|" + RingDb.Describe(schema) + "|" + System.Threading.Interlocked.Increment(ref counter);
			db.BuildTypes();
			if (provider == "sqlite" && connection.IndexOf(":memory:", StringComparison.OrdinalIgnoreCase) >= 0)
			{
				db.Database.OpenConnection();
			}
			db.Database.EnsureCreated();
			return db;
		}

		// ------------------------------------------------------------------ the classes

		private static string Unique(HashSet<string> taken, string name)
		{
			string result = name;
			int n = 2;
			while (!taken.Add(result)) result = name + (n++);
			return result;
		}

		private void BuildTypes()
		{
			AssemblyBuilder assembly = AssemblyBuilder.DefineDynamicAssembly(new AssemblyName("RingEntities" + schemaKey.GetHashCode().ToString("x") + counter), AssemblyBuilderAccess.Run);
			ModuleBuilder module = assembly.DefineDynamicModule("RingEntities");
			Dictionary<string, TypeBuilder> builders = new Dictionary<string, TypeBuilder>(StringComparer.OrdinalIgnoreCase);
			foreach (RingDb.Table table in tables)
			{
				builders[table.Name] = module.DefineType(table.Name, TypeAttributes.Public | TypeAttributes.Class);
			}
			/* the names of all the properties of each table */
			Dictionary<string, HashSet<string>> names = tables.ToDictionary(t => t.Name, t => new HashSet<string>(t.Columns.Select(c => c.Name), StringComparer.OrdinalIgnoreCase), StringComparer.OrdinalIgnoreCase);
			foreach (RingDb.Table child in tables)
			{
				foreach (RingDb.Column column in child.Columns)
				{
					if (column.References == null) continue;
					RingDb.Table parent = tables.FirstOrDefault(t => string.Equals(t.Name, column.References, StringComparison.OrdinalIgnoreCase));
					if (parent == null) throw new ArgumentException("The column " + child.Name + "." + column.Name + " references an unknown table " + column.References);
					string reference = column.Name.EndsWith("Id", StringComparison.OrdinalIgnoreCase) && column.Name.Length > 2 ? column.Name.Substring(0, column.Name.Length - 2) : column.Name + "Ref";
					navigations.Add(new Navigation
					{
						Child = child, Column = column, Parent = parent,
						ReferenceName = Unique(names[child.Name], reference),
						CollectionName = Unique(names[parent.Name], child.Name)
					});
				}
			}
			/* properties */
			foreach (RingDb.Table table in tables)
			{
				TypeBuilder builder = builders[table.Name];
				foreach (RingDb.Column column in table.Columns) AddProperty(builder, column.Name, column.Type);
				foreach (Navigation nav in navigations.Where(n => n.Child == table)) AddProperty(builder, nav.ReferenceName, builders[nav.Parent.Name]);
			}
			/* the collections are created by the constructor */
			foreach (RingDb.Table table in tables)
			{
				TypeBuilder builder = builders[table.Name];
				List<Navigation> collections = navigations.Where(n => n.Parent == table).ToList();
				Dictionary<Navigation, FieldBuilder> fields = new Dictionary<Navigation, FieldBuilder>();
				foreach (Navigation nav in collections)
				{
					Type list = typeof(List<>).MakeGenericType(builders[nav.Child.Name]);
					fields[nav] = AddProperty(builder, nav.CollectionName, list);
				}
				ConstructorBuilder ctor = builder.DefineConstructor(MethodAttributes.Public, CallingConventions.Standard, Type.EmptyTypes);
				ILGenerator il = ctor.GetILGenerator();
				il.Emit(OpCodes.Ldarg_0);
				il.Emit(OpCodes.Call, typeof(object).GetConstructor(Type.EmptyTypes));
				foreach (Navigation nav in collections)
				{
					Type list = typeof(List<>).MakeGenericType(builders[nav.Child.Name]);
					il.Emit(OpCodes.Ldarg_0);
					il.Emit(OpCodes.Newobj, TypeBuilder.GetConstructor(list, typeof(List<>).GetConstructor(Type.EmptyTypes)));
					il.Emit(OpCodes.Stfld, fields[nav]);
				}
				il.Emit(OpCodes.Ret);
			}
			foreach (RingDb.Table table in tables) types[table.Name] = builders[table.Name].CreateType();
		}

		private static FieldBuilder AddProperty(TypeBuilder type, string name, Type propertyType)
		{
			FieldBuilder field = type.DefineField("_" + name, propertyType, FieldAttributes.Private);
			System.Reflection.Emit.PropertyBuilder property = type.DefineProperty(name, PropertyAttributes.None, propertyType, null);
			MethodAttributes attributes = MethodAttributes.Public | MethodAttributes.SpecialName | MethodAttributes.HideBySig;
			MethodBuilder getter = type.DefineMethod("get_" + name, attributes, propertyType, Type.EmptyTypes);
			ILGenerator il = getter.GetILGenerator();
			il.Emit(OpCodes.Ldarg_0);
			il.Emit(OpCodes.Ldfld, field);
			il.Emit(OpCodes.Ret);
			MethodBuilder setter = type.DefineMethod("set_" + name, attributes, null, new[] { propertyType });
			il = setter.GetILGenerator();
			il.Emit(OpCodes.Ldarg_0);
			il.Emit(OpCodes.Ldarg_1);
			il.Emit(OpCodes.Stfld, field);
			il.Emit(OpCodes.Ret);
			property.SetGetMethod(getter);
			property.SetSetMethod(setter);
			return field;
		}

		// ------------------------------------------------------------------ the model

		protected override void OnConfiguring(DbContextOptionsBuilder options)
		{
			RingDb.UseProvider(options, provider, connection);
			options.ReplaceService<Microsoft.EntityFrameworkCore.Infrastructure.IModelCacheKeyFactory, SchemaCacheKeyFactory>();
		}

		protected override void OnModelCreating(ModelBuilder modelBuilder)
		{
			foreach (RingDb.Table table in tables)
			{
				Type type = types[table.Name];
				modelBuilder.Entity(type, builder =>
				{
					builder.ToTable(table.Name);
					foreach (RingDb.Column column in table.Columns)
					{
						Microsoft.EntityFrameworkCore.Metadata.Builders.PropertyBuilder property = builder.Property(column.Type, column.Name);
						if (column.Required) property.IsRequired();
						if (column.MaxLength > 0) property.HasMaxLength(column.MaxLength);
						if (column.HasDefault) property.HasDefaultValue(RingDb.Coerce(column.Default, column.Type));
						if (column.Converter != null) property.HasConversion(column.Converter);
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
						foreach (RingDb.Column key in table.Keys) builder.Property(key.Name).ValueGeneratedNever();
					}
					if (table.Filter != null && table.Filter.Length > 0)
					{
						ParameterExpression row = Expression.Parameter(type, "e");
						builder.HasQueryFilter(Expression.Lambda(RingDb.Condition(table, row, table.Filter), row));
					}
				});
			}
			foreach (Navigation nav in navigations)
			{
				modelBuilder.Entity(types[nav.Child.Name]).HasOne(types[nav.Parent.Name], nav.ReferenceName).WithMany(nav.CollectionName)
					.HasForeignKey(nav.Column.Name).OnDelete(nav.Column.OnDelete);
			}
		}

		// ------------------------------------------------------------------ entities

		private RingDb.Table Find(string entity)
		{
			RingDb.Table table = tables.FirstOrDefault(t => string.Equals(t.Name, entity, StringComparison.OrdinalIgnoreCase));
			if (table == null) throw new ArgumentException("Unknown table: " + entity);
			return table;
		}

		/* The .NET class of a table */
		public Type EntityType(string entity)
		{
			return types[Find(entity).Name];
		}

		/* A new entity (not yet added to the database) */
		public object New(string entity)
		{
			return Activator.CreateInstance(EntityType(entity));
		}

		/* The names of the properties of a table: columns first, then the navigation properties */
		public List<object> Properties(string entity)
		{
			RingDb.Table table = Find(entity);
			List<object> list = table.Columns.Select(c => (object)c.Name).ToRingList();
			list.AddRange(navigations.Where(n => n.Child == table).Select(n => (object)n.ReferenceName));
			list.AddRange(navigations.Where(n => n.Parent == table).Select(n => (object)n.CollectionName));
			return list;
		}

		private static PropertyInfo PropertyOf(object entity, string name)
		{
			PropertyInfo p = entity.GetType().GetProperty(name, BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
			if (p == null) throw new ArgumentException("The entity " + entity.GetType().Name + " has no property " + name);
			return p;
		}

		public object Get(object entity, string name)
		{
			object value = PropertyOf(entity, name).GetValue(entity);
			if (value is DateTime date) return date.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
			if (value is byte[] bytes) return Convert.ToHexString(bytes).ToLowerInvariant();
			return value;
		}

		public void Set(object entity, string name, object value)
		{
			PropertyInfo p = PropertyOf(entity, name);
			p.SetValue(entity, value == null ? null : (p.PropertyType.IsValueType || p.PropertyType == typeof(string) ? RingDb.Coerce(value, p.PropertyType) : value));
		}

		/* The columns of an entity as [ [name, value], ... ] */
		public List<object> ToRow(object entity)
		{
			RingDb.Table table = Find(entity.GetType().Name);
			return table.Columns.Select(c => (object)new RingList { c.Name, Get(entity, c.Name) }).ToRingList();
		}

		/* Set columns of an entity from [ [name, value], ... ] */
		public void Fill(object entity, object[] pairs)
		{
			foreach (object p in pairs)
			{
				object[] pair = (object[])p;
				Set(entity, (string)pair[0], pair[1]);
			}
		}

		private void SaveIfAuto()
		{
			if (AutoSave) Save();
		}

		public void Save()
		{
			try
			{
				SaveChanges();
			}
			catch (Exception e)
			{
				ChangeTracker.Clear();
				throw e is DbUpdateException && e.InnerException != null ? new InvalidOperationException(e.Message + " " + e.InnerException.Message, e) : e;
			}
		}

		public void Discard()
		{
			ChangeTracker.Clear();
		}

		/* Add an entity (and the entities it refers to); returns the key */
		public new object Add(object entity)
		{
			base.Add(entity);
			SaveIfAuto();
			RingDb.Table table = Find(entity.GetType().Name);
			if (!AutoSave) return null;
			return table.Keys.Count == 1 ? Get(entity, table.KeyColumn.Name) : new RingList(table.Keys.Select(k => Get(entity, k.Name)));
		}

		public new void Remove(object entity)
		{
			base.Remove(entity);
			SaveIfAuto();
		}

		/* The entity with the key (one value, or a list for a composite key), or null; it is tracked */
		public object FindEntity(string entity, object key)
		{
			RingDb.Table table = Find(entity);
			object[] values = key as object[] ?? new object[] { key };
			object[] converted = new object[values.Length];
			for (int i = 0; i < values.Length; i++) converted[i] = RingDb.Coerce(values[i], table.Keys[i].Type);
			return base.Find(EntityType(entity), converted);
		}

		private IQueryable SetOf(Type type)
		{
			return (IQueryable)typeof(DbContext).GetMethod("Set", Type.EmptyTypes).MakeGenericMethod(type).Invoke(this, null);
		}

		private static IQueryable Call(string name, IQueryable query, Type type, params object[] args)
		{
			MethodInfo method = typeof(Queryable).GetMethods().First(m => m.Name == name && m.GetParameters().Length == args.Length + 1);
			return (IQueryable)method.MakeGenericMethod(type).Invoke(null, new object[] { query }.Concat(args).ToArray());
		}

		/*
		**  The entities that match a query (same spec as RingDb.Query, plus ["include", [navigation, ...]]): they are tracked,
		**  so a changed property is saved by Save()
		*/
		public List<object> Query(string entity, object[] spec)
		{
			RingDb.Table table = Find(entity);
			Type type = EntityType(entity);
			IQueryable query = SetOf(type);
			object[] orders = new object[0];
			int skip = 0, take = -1;
			foreach (object item in spec)
			{
				object[] pair = (object[])item;
				switch (((string)pair[0]).ToLowerInvariant())
				{
					case "where":
					{
						object[] condition = (object[])pair[1];
						if (condition.Length == 0) break;
						ParameterExpression row = Expression.Parameter(type, "e");
						query = Call("Where", query, type, Expression.Lambda(RingDb.Condition(table, row, condition), row));
						break;
					}
					case "orderby": orders = pair[1] is object[] list ? list : new object[] { pair[1] }; break;
					case "skip": skip = Convert.ToInt32(pair[1], CultureInfo.InvariantCulture); break;
					case "take": take = Convert.ToInt32(pair[1], CultureInfo.InvariantCulture); break;
					case "ignorefilters": query = EntityFrameworkQueryableExtensionsIgnore(query, type); break;
					case "include":
					{
						MethodInfo include = typeof(EntityFrameworkQueryableExtensions).GetMethods().First(m => m.Name == "Include" && m.GetParameters().Length == 2 && m.GetParameters()[1].ParameterType == typeof(string)).MakeGenericMethod(type);
						foreach (object path in pair[1] is object[] paths ? paths : new object[] { pair[1] })
						{
							query = (IQueryable)include.Invoke(null, new object[] { query, (string)path });
						}
						break;
					}
					default: throw new ArgumentException("Unknown query item: " + pair[0]);
				}
			}
			bool first = true;
			foreach (object o in orders)
			{
				object[] order = o is object[] pair ? pair : new object[] { o, "asc" };
				RingDb.Column column = RingDb.ColumnOf(table, order[0]);
				bool descending = order.Length > 1 && string.Equals(Convert.ToString(order[1], CultureInfo.InvariantCulture), "desc", StringComparison.OrdinalIgnoreCase);
				ParameterExpression row = Expression.Parameter(type, "e");
				LambdaExpression key = Expression.Lambda(RingDb.PropertyOf(row, column), row);
				string name = first ? (descending ? "OrderByDescending" : "OrderBy") : (descending ? "ThenByDescending" : "ThenBy");
				MethodInfo method = typeof(Queryable).GetMethods().First(m => m.Name == name && m.GetParameters().Length == 2).MakeGenericMethod(type, column.Type);
				query = (IQueryable)method.Invoke(null, new object[] { query, key });
				first = false;
			}
			if (skip > 0) query = Call("Skip", query, type, skip);
			if (take >= 0) query = Call("Take", query, type, take);
			List<object> result = new RingList();
			foreach (object o in query) result.Add(o);
			return result;
		}

		private static IQueryable EntityFrameworkQueryableExtensionsIgnore(IQueryable query, Type type)
		{
			MethodInfo method = typeof(EntityFrameworkQueryableExtensions).GetMethods().First(m => m.Name == "IgnoreQueryFilters" && m.GetParameters().Length == 1).MakeGenericMethod(type);
			return (IQueryable)method.Invoke(null, new object[] { query });
		}

		public List<object> All(string entity)
		{
			return Query(entity, new object[0]);
		}

		public long Count(string entity, object[] condition)
		{
			RingDb.Table table = Find(entity);
			Type type = EntityType(entity);
			IQueryable query = SetOf(type);
			if (condition != null && condition.Length > 0)
			{
				ParameterExpression row = Expression.Parameter(type, "e");
				query = Call("Where", query, type, Expression.Lambda(RingDb.Condition(table, row, condition), row));
			}
			MethodInfo count = typeof(Queryable).GetMethods().First(m => m.Name == "LongCount" && m.GetParameters().Length == 1).MakeGenericMethod(type);
			return (long)count.Invoke(null, new object[] { query });
		}

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
				Save();
				transaction.Commit();
			}
			catch
			{
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
			try { transaction.Rollback(); }
			finally { transaction.Dispose(); transaction = null; }
		}

		public void Close()
		{
			Dispose();
			Microsoft.Data.Sqlite.SqliteConnection.ClearAllPools();
		}
	}
}
