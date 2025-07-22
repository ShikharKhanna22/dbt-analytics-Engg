

### Introduction to LookML

- LookML, short for Looker Modeling Language, is the language that is used in Looker to create semantic data models.
- You can use LookML to describe dimensions, aggregates, calculations, and data relationships in your SQL database.
- Looker uses a model that is written in LookML to construct SQL queries against a particular database.
- LookML provides predefined data types and syntax for data modeling.
- LookML is independent of particular SQL dialects, and it encapsulates SQL expressions to support any SQL implementation.
- LookML fosters DRY style ("don't repeat yourself"), meaning you write SQL expressions once, in one place, and Looker uses the code repeatedly to generate ad hoc SQL queries.
- Business users can then use the results to build complex queries in Looker, focusing only on the content they need, not the complexities of SQL structure.


### LookML projects

- LookML is defined in projects. A LookML project is a collection of files including at least model and view files,
- and optionally other types of files, that are typically version-controlled together through a Git repository.
- The model files contain information about which tables the project will use and how the tables should be joined.
- The view files describe how information is calculated about each table (or across multiple tables if the joins permit this).
- LookML separates structure from content, so the query structure (how tables are joined) is independent of
  - the query content (columns, derived fields, aggregate functions, and filtering expressions).

Looker queries are based on LookML project files. 
- Data analysts use LookML to create and maintain data models
  - that define the data structure and business rules for the data that is being analyzed.
  - The Looker SQL generator translates LookML into SQL, which lets business users query without writing any LookML or SQL.
- Business users use the Looker query builder, or the Explore interface, to create queries that are based on the data model that Looker analysts define.
  - Users can select dimensions, measures, and filters to create custom queries that are based on their own questions and to generate their own insights.
  - When a user creates a query, it is sent to the Looker SQL generator, which translates the query into SQL.
    - The SQL query is executed against the database, and then Looker returns the formatted results to the user in the Explore interface.
    - The user can then visualize the results and generate insights.

```
Model files with extension .model.lkml
View files with extension .view.lkml
Dashboard files with extension .dashboard.lookml
Data files with extension .topojson or .geojson or .json
Document files with extension .md
Project manifest files that are always named manifest.lkml
Manifest lock files with extension .lkml
Locale strings files with extension .strings.json
Explore files with extension .explore.lkml
Data test files with extension .lkml
Refinements files with extension .lkml
```

### left navigation panel
- The Explore menu is organized by model names. Under each model name is a list of available Explores that are defined in that model.
- Users can search for a specific Explore.
- Developers can define descriptions for Explores, which users can view by hovering over the Explore name in the Explore menu.
- The field picker pane is organized by view names.
  - Under each view name is a list of available fields from the tables included in that view.
  - Most views show both dimensions and measures. 
- Users can select multiple measures on which to base the query.
- Users can apply options like filters and pivots in the field picker pane.
- Users can refine the terms of the query.
- Users can choose a visualization type to apply to the query results.
- Running this Explore generates a SQL query that returns both a data table and a visualization.

---

minimal LookML project for an e-commerce store, which has a model file — ecommercestore.model.lkml — and two view files — orders.view.lkml and customers.view.lkml:

- modular LookML setup for an e-commerce reporting model 💼🧾

```lookml
######################################
# FILE: ecommercestore.model.lkml    #
# Define the explores and join logic #
######################################
connection: order_database
include: "*.view.lkml"
explore: orders {
  join: customers {
    sql_on: ${orders.customer_id} = ${customers.id} ;;
  }
}
```
- This model file acts as the entry point for exploring the data:
- connection: order_database: Specifies which database these views pull from.
- include: "*.view.lkml": Dynamically includes all view files in the project. Helps keep your codebase tidy!
- Explore orders: Joins Orders-view to customers-view based on matching orders.customer_id with customers.id.
- This model lets users:
  - Start exploring from orders
  - Dive into individual orders via drill
  - See connected customer details
  - Analyze totals, timelines, and location-based patterns

```lookml
##########################################################
# FILE: orders.view.lkml                                 #
# Define the dimensions and measures for the ORDERS view #
##########################################################
view: orders {
  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: customer_id {      # field: orders.customer_id
    sql: ${TABLE}.customer_id ;;
  }
  dimension: amount {           # field: orders.amount
    type: number
    value_format: "0.00"
    sql: ${TABLE}.amount ;;
  }
  dimension_group: created {                # generates fields:
    type: time                              # orders.created_time, orders.created_date
    timeframes: [time, date, week, month]   # orders.created_week, orders.created_month
    sql: ${TABLE}.created_at ;;
  }
  measure: count {             # field: orders.count
    type: count                # creates a sql COUNT(*)
    drill_fields: [drill_set*] # list of fields to show when someone clicks 'ORDERS Count'
  }
  measure: total_amount {
    type: sum
    sql: ${amount} ;;
  }
  set: drill_set {
    fields: [id, created_time, customers.name, amount]
  }
}
```
This view defines fields from the orders table:

🔹 Dimensions
- id: Primary key, numeric.
- customer_id: Foreign key linking to customers.
- amount: The monetary value of each order, formatted with two decimal places.
- created (dimension group): Offers multiple timeframes based on created_at: time, date, week, month.
  - This helps users analyze order activity over different periods.

🔸 Measures
- count: Counts rows in orders.
- Has drill fields defined by `drill_set*`, which references a reusable set of fields.
- total_amount: Sums up all order amounts.

🔧 Set: drill_set
- Includes fields to display when drilling into the orders.count measure:
  - id, created_time, customers.name, amount
  - This provides a meaningful snapshot of each order when drilling down from an aggregate.


```lookml
#############################################################
# FILE: customers.view.lkml                                 #
# Define the dimensions and measures for the CUSTOMERS view #
#############################################################
view: customers {
  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: city {                    # field: customers.city
    sql: ${TABLE}.city ;;
  }
  dimension: state {                   # field: customers.state
    sql: ${TABLE}.state ;;
  }
  dimension: name {
    sql: CONCAT(${TABLE}.firstname, " ", ${TABLE}.lastname) ;;
  }
  measure: count {             # field: customers.count
    type: count                # creates a sql COUNT(*)
    drill_fields: [drill_set*] # fields to show when someone clicks 'CUSTOMERS Count'
  }
  set: drill_set {                     # set: customers.drill_set
    fields: [id, state, orders.count]  # list of fields to show when someone clicks 'CUSTOMERS Count'
  }
}
```

🔹 Dimensions
- id: Primary key.
- city & state: Geographic data.
- name: A custom full name field combining first and last names.

🔸 Measure: count
- Counts customer records.
  - Drill fields come from the drill_set:
  - id, state, and orders.count
  - Useful for seeing not only customer details but also how many orders they’ve placed.


---

### LookML Models

A LookML project is a collection of LookML files that tell Looker how to connect to your database, how to query your data, and how to control the user interface's behavior. A LookML project consists of at least one model file and at least one view file, and possibly some of the other types of files described on this page

- A model file specifies a database connection and the set of Explores that use that connection.
- A model file also defines the Explores themselves and their relationships to other views.
- An Explore is a starting point for querying your data. In SQL terms, an Explore is the FROM clause of a query.
- The Explores that you define in the model are seen by your users when they look at the Looker Explore menu.
- the model file is where you define which data tables should be used (as included views) and how they should be joined together, if necessary.


- A model is a customized portal into the database, designed to provide intuitive data exploration for specific business users.
- Multiple models can exist for the same database connection in a single LookML project.
- Each model can expose different data to different users.
  - For example, sales agents need different data than company executives, and so
  - you would probably develop two models to offer views of the database appropriate for each user.

> A model specifies a connection to a single database. A developer also defines a **model's Explores** within the model file. By default, Explores are organized under the model name in which they are defined. Your users see models listed in the Explore menu.



[sample model file](https://cloud.google.com/looker/docs/lookml-project-files)

```lookml
connection: "thelook_events"

explore: inventory_items {
  join: products {
    type: left_outer
    sql_on: ${inventory_items.product_id} = ${products.id} ;;
    relationship: many_to_one
  }

  join: distribution_centers {
    type: left_outer
    sql_on: ${products.distribution_center_id} = ${distribution_center.id} ;;
    relationship: many_to_one
  }
}

```
This LookML explore starts with `inventory_items`, joins to `products` to enrich the data, and then joins to `distribution_centers` to see where those products are distributed from. Using left joins ensures full visibility into all inventory items, even those missing some relational data.

- defines an Explore called `inventory_items`, along with its joined views
- Explores allow users to start querying data from a specific point.
- This LookML definition causes Inventory Items to appear in the Explore section of the Looker navigation and
  - joins data from the products and distribution_centers views to the inventory_items view.
- Join type: left_outer — keeps all inventory_items, even if there’s no matching row in products.
- Join condition: inventory_items.product_id must match products.id.
- Relationship: many_to_one means many inventory_items can be related to one product.

---

### View files

- A view file generally defines a single "view" within Looker. A view corresponds to either a single table in your database or a single derived table.
- The view file specifies a table to query and the fields (dimensions and measures) to include from that table so that users can create queries with those fields in the Looker UI.
- Within each view's curly braces, { }, are field definitions, which usually correspond to a column in the underlying table or a calculation in Looker.
  - Looker categorizes most of these definitions as either dimensions or measures.



- A view declaration defines a list of fields (dimensions or measures) and their linkage to an underlying table or derived table.
- In LookML a view typically references an underlying database table, but it can also represent a derived table.
- A view may join to other views. The relationship between views is typically defined as part of an Explore declaration in a model file.
- By default, view names appear at the beginning of dimension and measure names in the Explore data table.
  - This naming convention makes it clear which view the field belongs to. 


In the following example of a view file, the orders.view file includes definitions for the id, status, and user_id dimensions, the created dimension group, and the count measure. This view cleanly models the orders table with `Key dimensions for ID, status, user, and timestamps` and `One measure for total order count` and Setup for drill-through interactivity

```lookml
view: orders {
  sql_table_name: demo_db.orders ;;
  drill_fields: [id]
# Specifies which fields are shown when drilling into aggregated measures.
# it's set to id - user can click on aggregated data and explore more details starting from the id.

  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension: user_id {
    type: number
    # hidden: yes
    sql: ${TABLE}.user_id ;;
  }
# The hidden: yes line is commented out. If enabled, this field would be excluded from the explore UI.

    dimension_group: created {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.created_at ;;
  }
# This is a time-based dimension group created from the created_at column.
# The timeframes array gives users multiple granularities to filter/order/analyze time-related data.


  measure: count {
    type: count
    drill_fields: [id, users.id, users.first_name, users.last_name, order_items.count]
  }
# Counts the number of records in the orders view.
# When users drill into the count, they'll be shown multiple related fields
# including user info and order item count.
}
```

### Drilling lets users: Click on a value (e.g., a total or count)
- Reveal a detail view showing rows that contributed to that value
- See predefined fields (set by drill_fields) that help explain the data
  - Each individual order ID (id)
  - User info for who placed each order (users.id, users.first_name, users.last_name)
  - How many items were in each order (order_items.count)
- So instead of just seeing “250 orders,” you can explore:
  - Who placed the orders (user_details)
  - Which orders they placed (order_id)
  - How big each order was (order_count)
 
---

### Explore files

- An Explore is a view that users can query.
- An Explore is the starting point for a query or, in SQL terms, the FROM in a SQL statement.
- Explores are usually defined within a model file.
  - However, sometimes you need a separate Explore file for a derived table, or to extend or refine an Explore across models.
- Not all views are Explores, because not all views describe an entity of interest.
  - For example, a States view that corresponds to a lookup table for state names doesn't warrant an Explore, because business users never need to query it directly.
  - On the other hand, business users probably want a way to query an Orders view, and so defining an Explore for Orders makes sense.
- your users can see Explores listed in the Models-Explore menu. Explores are listed below the names of the models they belong to.
- By convention, Explores are declared in the model file with the explore parameter. OR separate file for reusability, refactoring and modularity.
- In this following example of a model file, the orders Explore for an ecommerce database is defined within the model file.
- The views orders and customers that are referenced within the explore declaration are defined elsewhere, in their respective view files.

```lookml
connection: order_database
include: "filename_pattern"

explore: orders {
  join: customers {
    sql_on: ${orders.customer_id} = ${customers.id} ;;
  }
}
```

include parameter is used to specify the files that will be available for the model to reference. The explore declaration in this example also specifies join relationships between views. 


### Dimension and measure fields

Views contain fields, mostly dimensions and measures, which are the fundamental building blocks for Looker queries.
- dimension is a groupable field and can be used to filter query results. It can be any of the following:
  - An attribute, which has a direct association to a column in an underlying table
  - A fact or numerical value
  - A derived value, computed based on the values of other fields in a single row
- In Looker, dimensions always appear in the GROUP BY clause of the SQL that Looker generates.
- For example, dimensions for a Products view might include product name, product model, product color, product price, product created date, and product end-of-life date.



- A measure is a field that uses a SQL aggregate function, such as COUNT, SUM, AVG, MIN, or MAX.
- Any field computed based on the values of other measure values is also a measure.
- Measures can be used to filter grouped values.
- For example, measures for a Sales view might include total items sold (a count), total sale price (a sum), and average sale price (an average).
- The behavior and expected values for a field depend on its declared type, such as string, number, or time. For measures, types include aggregate functions, such as sum and percent_of_previous. 

In Looker, fields are listed on the Explore page in the field picker. You can expand a view in the field picker to show the list of fields that are available to query from that view.

```lookml
view: orders {
  dimension: id {
    primary_key: yes
    type: number
    sql: ${TABLE}.id ;;
  }
  dimension: customer_id {
    sql: ${TABLE}.customer_id ;;
  }
  dimension: amount {
    type: number
    value_format: "0.00"
    sql: ${TABLE}.amount ;;
  }
  dimension_group: created {
    type: time
    timeframes: [date, week]
    sql: ${TABLE}.created_at ;;
  }
# dimension_group, creates multiple time-related dimensions at once

  measure: count {
    type: count           # creates sql COUNT(orders.id)
    sql: ${id} ;;
  }
  measure: total_amount {
    type: sum             # creates sql SUM(orders.amount)
    sql: ${amount} ;;
  }
}
```

### Joins

- As part of an explore declaration in model file, each join declaration specifies a view that can be joined into the Explore. 
- When a user creates a query that includes fields from multiple views, Looker automatically generates SQL join logic to bring in all fields correctly.




https://cloud.google.com/looker/docs/what-is-lookml
https://cloud.google.com/looker/docs/sql-experts-view
https://cloud.google.com/looker/docs/reference/param-dimension-filter-parameter-types
https://cloud.google.com/looker/docs/reference/param-measure-types
https://cloud.google.com/looker/docs/reference/param-field-dimension
https://cloud.google.com/looker/docs/reference/param-field-parameter
https://cloud.google.com/looker/docs/reference/param-field-filter
https://cloud.google.com/looker/docs/working-with-joins
https://cloud.google.com/looker/docs/reference/param-model-include
