---
title: "Tutorial 73: Reports with SQL"
lead: Databases are good at questions. This lesson asks them with SQL — JOIN to combine tables, GROUP BY to total, HAVING and WHERE to filter, LEFT JOIN to keep everybody, and a sub-query to compare with an average.
---

## What you will learn

- joining two tables with `JOIN … ON`,
- totals per group with `GROUP BY` and the aggregates `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`,
- the difference between `WHERE` and `HAVING`,
- `LEFT JOIN` to keep rows that have no partner,
- a sub-query,
- parameters instead of pasted values.

## The data

Two tables ([tutorial 17](tut-17-databases.html) explains how to create them): **Customers** (Ann and Cy in Cairo, Bob in Oslo, Dee in Tokyo) and **Orders** with a `CustomerId` that points to the customer, a product, an amount and a month. Dee has never ordered anything — that matters in step 4.

## The program

{{file:docs/tutorials/t73_sql_reports.ring}}

{{output:docs/tutorials/t73_sql_reports.ring}}

## How it works

`oDb.sqlRows(sql, parameters)` runs any `SELECT` and returns the rows as lists of `[column, value]` pairs; `dbValue(row, "Total")` reads one column. The `show` helper prints a few columns as a small table.

### 1. JOIN

`FROM Orders o JOIN Customers c ON c.Id = o.CustomerId` puts together each order and the customer whose `Id` equals its `CustomerId`. `o` and `c` are short *aliases* of the tables. The result has one row per order, with the customer's name next to it.

### 2. GROUP BY

`GROUP BY c.Name` makes **one row per customer**; `COUNT(o.Id)` and `SUM(o.Amount)` are calculated over the orders of that customer. `ORDER BY Total DESC` puts the biggest first. Every column in `SELECT` must be either in `GROUP BY` or inside an aggregate.

### 3. WHERE and HAVING

`WHERE` removes **rows** *before* they are grouped (only the January orders); `HAVING` removes **groups** *after* the totals are known (only customers with a total above 300). A condition on an aggregate can only go in `HAVING`.

### 4. LEFT JOIN

A plain `JOIN` drops rows that have no partner: Dee does not appear in steps 1–3. `LEFT JOIN` keeps **every row of the left table** and fills the missing side with empty values, so `COUNT(o.Id)` is 0 for Dee. Use it for reports such as "all customers, also those who did not buy".

### 5. Groups from another table

The city is in `Customers` and the amount in `Orders`; the join lets you total by a column of either.

### 6. A sub-query

`WHERE Amount > (SELECT AVG(Amount) FROM Orders)` first calculates the average (318.57…) and then keeps the larger orders. A query inside a query is fine as long as the inner one returns one value.

### 7. scalar

`oDb.scalar(sql)` returns the first column of the first row — handy for a count or a total.

> [!WARNING] Never put values into SQL by adding strings: `"... WHERE Month = '" + cMonth + "'"` lets a user write SQL into your query (*SQL injection*). Use the parameters `{0}`, `{1}`, … and pass the values in the list, as steps 3 does.

## What you learned

- `JOIN`, `LEFT JOIN`,
- `GROUP BY` with aggregates,
- `WHERE` against `HAVING`,
- sub-queries and `scalar`,
- parameters against injection.

## Exercises

1. Show the average order per customer, rounded.
2. List the products that were never ordered by a customer from Cairo.
3. Find the month with the highest total.
4. Add a `Products` table with prices and join it to the orders.

## Next

[Tutorial 74: Asking the computer](tut-74-system.html)
