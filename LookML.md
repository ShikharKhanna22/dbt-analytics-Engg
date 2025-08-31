

### Introduction to LookML - As per official documentation

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

----

Day2: July, 22

### UDEMY: Looker and LookML - George Smarts - 9 hour

**Section 10: LookML basics - 55. Explore the LookML environment**

Development vs Production Mode - switching

Go to the home page > development mode turned on > click on develop > go to projects

- Two sample lookML projects that are ready - e-commerce and flights.
- And this is a this is the actual development environment within Looker.
- This is where we write our lookml. We create our models, explores, views.


#### 56. Elements of LookML
- So it all starts with a Lookml project - which is going to house everything under it.
- Once you have the Lookml project, the lowest level is the different fields that are going to come from
the tables at the backend. dimensions, Measures and field sets.
- All these fields are located in the tables at the backend, and you use these tables in order to create
views.
- These views are then used in a model, and the way you expose the views for the users in a model with
explores and use joins in order to join the different views (which correspond to tables at the back end)
- which will make it possible for you to integrate data from different datasets and do in-depth analysis.
- And then obviously all this can be used in order to create dashboards and visualizations.


#### 57. Fields


- lowest level in the lookML hierarchy, and this level is the field.
- There are two main types of fields. The first one is dimensions.
- fields - represent a (one) column of data in the database table at the back end.
  - In some cases, they can actually represent a transformation or combination of different columns in the back end.
- Then you have measures. pretty much usually a sum, a max or a count that provides you a numerical number.
  - SQL query that creates this numerical number based on specific criteria.
- Another type of field that I don't see people mention is the filter type of field.
- In general, you don't need to create your own filters. A specific column. Usually the dimensions and measures that you have created will be available to use for filtering.
- However, there are some specific cases in which you want to create a filter type of field

The most important thing to remember here is that the lowest level within the Lookml hierarchy is the field, and there are two main types of fields. We have the dimensions and we have the measures.

#### 58. Views

- Second level in the lookML hierarchy, after fields
- Views are a representation of tables in a database, where dimensions, measures, dimension_groups will be defined.
- tables can come from a database or derived within looker


#### 59. Explore

- The next level within the lookml hieararchy is the explore, and you will find the explore menu here within the top navigation bar.
- explore is based on one or multiple views that are exposed for the analysts to use.
- within a model you create the explore and the explore is based on one or multiple views.
- creating an explore allows you to use this view when creating logs or dashboards.
- From the Explorer menu, click on users (explore), which opens our navigations on the left.
- You see the different dimensions And we have a few measures and we can now use this explorer in order to start building our look here.
- Now, if we go to develop menu and if I go to e-commerce and I find the view-users, You see that all the Different dimensions and measures that we have within the explore-users is actually here within the view-users.
- And then if I go to the e-commerce model, here we have an explore-users.
- Explore is just how you expose the views or combinations of views within this EXPLORE menu that you can use for analysis


#### 60. Models

- in order to use the explores, you need to house them somewhere. And this is where the model comes.
- we are on the e-commerce model file here and within this model we have all the different explores that are related to the e-commerce project.
- you house all the explores and you define some settings such as which database connection is to be used.
- If you want to create a new model, you simply click here and click on Create Model.
- the first line identifies the connection that's to be used in order to query the data.
- the second line includes all the different views that are available in this project, with this wild card here.
- However, if you want to include only specific views, you can do that.
- we have all the different explorers stated here that we want to use.
- notice that for order-items (explore) we have a few different joins which allows us to join the different views together
- The most important thing to for you to remember for now is that Models House the explores that we use within a project.

#### 61. Project

- highest level in the hierarchy within Lookml is the project.
- A project is a collection of files that describe the objects, connections, the models, the views, the user interface elements that will be used when we query the data using SQL.
- So if we go to develop, we will see that we are in the project e-commerce, all these different files here on the left, they describe how the database tables relate to each other and how Looker should understand these tables.
- There are basically two main types of files here - You have the model. And you have the view files 
- A model will specify the connection to a single database. And this is where the developer can define their explores. So within one model file you can have multiple explores.
- So we are in the project e-commerce, and then within this project we are in the model e-commerce here and here we define the explore (order_items, users, user_order_facts, inventory_items and etcetera).
- And now if we go to the Explores menu, under e-commerce-model you see the same explores that we have listed here. So the Explore menu here on the top is actually organized by the model names.



- Let's now explore the different menus within the project. So first we have the files browser here.
- we can create multiple types of files, we can create a folder under which you can put files, you can create a model from here. You can create a view either from a table or from scratch.
- you can create a project manifest. A project Manifest file is usually used to specify module localization settings to add an extension to your project, Add custom visualizations to your project, or specify other projects that are to be imported into the current project.
- You can create a dashboard from here, you can create a document. You can also create a local strings file and also you can create a generic lookml file.
- the two main types of files that you're going to have in a project are going to be the model and the View. 


> So this is what a project really is. It's pretty much the highest level in the hierarchy that's going to be used in order to house absolutely everything from models, views, manifest files and all the different settings.


- if I go to the second option on the menu. I'm gonna go to the object browser, which is pretty much the model and the different explores.
- And if I expand on the explores, can see the dimensions and measures within every single explorer.
- If you want to get an understanding of what's within a project, I'll advise you to come here to the object browser because it's going to be much easier to understand the structure.


- Then you can use the find and replace function from here. Remember that lookML is case sensitive.
- git actions, So Looker uses git to record changes and manage file versions. So this is going to be what's going to be used for the version control for your project.
- each project within Lookml will correspond to a git repository and each developer branch will correlate to a git branch.
- And then the last button here in the menu is settings. And here you change the project configurations. For example, this project is called e-commerce. From here you can change the name, you can put the Git production branch name, you can choose how clean you want your code to be before you commit this to production. For example, you can decide that it's mandatory to fix both errors and warnings before committing only errors.
- Then you have options for GitHub integration. Deployment and then you can switch to branch management.

#### 62. Dimension and Measure Fields

- go to the **object browser** and then we go to the orders-view here. And then we open the Different dimensions and measures that we have within this view.
- So here we really have three different types of fields. So we have the dimension here. We have Dimension Group.
- A dimension group is used to group together. For example, a time period where you want to use year, month, quarter week. So these are the dimensions that are relevant to each other and you pretty much group them together.
- And then you have the measure here, which is the count.


To see where are these defined? go to the **file browser** here and now open the orders view. So we have the view orders. Then we have the connection to the table.
- And then we have the different dimensions here defined.
- Then here's the Dimension group and the type is time. The data type is datetime. And here are the time frames. So we have the different time periods that we grouped together. And you see that it's created at. So this is when the order was placed.

#### 63. Dimension Types

we have 7 types of dimensions.
we are again under the eCommerce project and I'm going to go here to the users view.
And here we're going to have a look at the first type of dimension, which is the string.
This is really the default dimension type, second type here, which is the number.


third type here, which is the YES/NO. So, for example, here the condition is status equal to complete.
So if you want to show all the complete orders and have a column that's going to allow us to say is
complete, yes or no, then we simply create this dimension.


And the next one is the tier.
allow you to create really buckets for the data within your database.


fifth type of dimension, we have a dimension called location, and the type is location.
For this, you need the latitude and longitude information available.
This can be really useful if you want to map certain locations within Looker.

sixth type of dimension is going to be the distance.
allows us to calculate the distance between the distribution center and the user location.
So you need two locations in order for this to work.

Seventh type of dimension is also here under users.
This is the zip code and this simply is going to allow you to specify a zip code.
And these are really the seven main types of dimension fields within Looker.

#### 64. Create Folders and tidy up your space

---- 

Looker - Packt

Fields, dimensions, measures
Field - columns, 2 subsets
dimensions - qualitative/discrete data to categorize, segment, reveal details about data
measures - numeric, quantitative, agrregatable, continuous, not-discrete to measure, compare

---

Explores, looks, dashboard
3 different types of objects that serve distinct purposes in the Looker ecosystem:

**Explores** - starting point for exploration for analysts, foundation of your data model, capsule for data with all the data you ever need to analyze. They define how users can query and analyze data by specifying which dimensions and measures are available, how tables join together, and what filters can be applied. Think of an explore as creating a "lens" through which users can examine your data. For example, you might have an explore called "sales_analysis" that joins your orders, customers, and products tables, allowing users to slice and dice sales data in various ways.

**Looks or Reports** are saved queries or reports built on top of explores. When a user creates a visualization or report using an explore, they can save the analysis/report as a look for future reference or sharing. Looks contain the specific field selections, filters, and visualization settings that define a particular analysis. They're essentially bookmarked queries that can be easily accessed and shared with others.

**Dashboards** are collections/compilation of multiple looks (and other content) organized on a single page to provide a comprehensive view of key metrics and insights. They're like executive summaries that bring together related visualizations to tell a cohesive story about your data. A sales dashboard might include looks showing revenue trends, top products, regional performance, and conversion rates all in one place. Enforces interaction between looks.

The relationship flows like this: Explores provide the data structure → Looks create specific analyses → Dashboards organize multiple looks into comprehensive views. Users typically interact with looks and dashboards in the Looker interface, while explores are the underlying LookML code that makes it all possible.

Boards and Folders
The key difference here again is that folders are used to store looks and reports and dashboards, whereas boards are used to organize them.


---

**SQL (Structured Query Language)** is a standard programming language for managing and querying relational databases. It's used to directly retrieve, insert, update, and delete data from database tables. SQL is procedural - you write specific commands telling the database exactly what to do and how to do it.

**LookML** is Looker's modeling language that sits on top of SQL. Instead of writing raw SQL queries, you use LookML to define a semantic layer that describes your data structure, relationships, and business logic. LookML is declarative - you describe what your data means and how it relates, then Looker automatically generates the appropriate SQL queries.

Here are the key differences:

**Abstraction Level**: SQL works directly with database tables and columns, while LookML creates business-friendly abstractions like "Customer Lifetime Value" or "Monthly Recurring Revenue" that translate to complex SQL behind the scenes.

**Reusability**: SQL queries are typically written for specific use cases, while LookML definitions can be reused across many different analyses. Once you define a measure in LookML, anyone can use it without rewriting SQL.

**Maintenance**: With SQL, if your database schema changes, you need to update every affected query manually. With LookML, you update the model definition once, and all dependent queries automatically adapt.

**User Access**: SQL requires technical knowledge to write queries, while LookML enables non-technical users to explore data through a web interface by clicking and dragging the dimensions and measures you've defined.

**Generated Output**: LookML automatically generates optimized SQL queries based on user selections, handling complex joins, aggregations, and filtering logic that would require careful manual coding in pure SQL.

Think of LookML as creating a user-friendly interface and business logic layer on top of your raw SQL data, making analytics accessible to a broader audience while maintaining consistency and reducing errors.

---

In LookML, these three components form a hierarchical structure that builds your data model from the ground up:

**Views** are the foundation - they define individual data objects, typically corresponding to database tables or derived tables. A view contains the dimensions (attributes like customer name, product category, order date) and measures (calculations like count of orders, sum of revenue, average order value) that describe that specific data source. Views also handle data transformations, SQL customizations, and formatting rules for their fields.

**Models** are configuration files that tie everything together at the highest level. They specify which database connection to use, which views to include, and contain the explores that users can access. Models also define global settings like caching policies, access permissions, and datagroups for managing data freshness. Think of a model as the "package" that organizes related views and explores.

**Explores** sit between models and views, defining how users can query and analyze the data. They specify which view serves as the base table and how other views can be joined to it. Explores control what dimensions and measures users can access, define join relationships, set default filters, and establish the query scope. They're essentially the "user interface" for data exploration.

The relationship flows like this:
- **Models** contain multiple **Explores**
- **Explores** are built from one or more **Views** 
- **Views** define the actual data fields and transformations

For example, you might have:
- A **view** called `orders` with dimensions like order_date and customer_id, plus measures like total_revenue
- Another **view** called `customers` with customer attributes
- An **explore** called `sales_analysis` that joins the orders and customers views
- A **model** file that includes this explore and specifies the database connection

Users interact with explores in the Looker interface, which pulls from the underlying views according to the model's configuration.

---

Here are the most common parameters used to define and configure views in LookML, with practical examples:

#### Basic View Structure
**datagroup_trigger** - Controls when derived tables refresh
**sql_table_name** - Specifies the underlying database table or schema.table

```lookml
view: orders {
  sql_table_name: ecommerce.fact_orders ;;
}
```

**derived_table** - Creates views from custom SQL queries instead of existing tables
```lookml
view: customer_summary {
  derived_table: {
    sql: SELECT 
           customer_id,
           COUNT(*) as total_orders,
           SUM(order_total) as lifetime_value
         FROM orders 
         GROUP BY customer_id ;;
  }
}

view: daily_summary {
  derived_table: {
    datagroup_trigger: ecommerce_default_datagroup
    sql: SELECT date, SUM(revenue) FROM orders GROUP BY date ;;
  }
}
```

## View-Level Parameters

**suggestions** - Controls field suggestions in the explore interface
```lookml
view: products {
  suggestions: no  # Disables auto-suggestions for this view
  
  dimension: product_name {
    type: string
    sql: ${TABLE}.name ;;
    suggestions: yes  # Override view-level setting for this field
  }
}
```

#### Field Definitions

**dimension** - Defines attributes/categorical data
```lookml
dimension: customer_id {
  type: number
  sql: ${TABLE}.customer_id ;;
  primary_key: yes
}

dimension: customer_tier {
  type: string
  sql: CASE 
         WHEN ${lifetime_value} > 1000 THEN 'Premium'
         WHEN ${lifetime_value} > 500 THEN 'Standard' 
         ELSE 'Basic'
       END ;;
  label: "Customer Tier"
  description: "Customer segmentation based on lifetime value"
}

dimension: conversion_rate {
  type: number
  sql: ${conversions} / ${visitors} ;;
  value_format_name: percent_2  # 15.67%
}

**dimension** with **drill_fields** - Defines drill-down paths

dimension: category {
  type: string
  sql: ${TABLE}.category ;;
  drill_fields: [subcategory, product_name, brand]
}
```

**measure** - Defines calculations and aggregations
```lookml
measure: total_revenue {
  type: sum
  sql: ${TABLE}.order_total ;;
  value_format_name: usd
}

measure: order_count {
  type: count
  drill_fields: [order_id, customer_name, order_date]
}

measure: average_order_value {
  type: average
  sql: ${TABLE}.order_total ;;
  value_format_name: usd_0
}
```

#### Dimension Groups (Date/Time Handling)

**dimension_group** - Creates multiple time-based dimensions from a single date field
```lookml
dimension_group: created {
  type: time
  timeframes: [raw, date, week, month, quarter, year]
  sql: ${TABLE}.created_at ;;
}

# This automatically creates:
# created_raw, created_date, created_week, created_month, etc.
```

**filter** - Creates filter-only fields for user input
```lookml
filter: date_range {
  type: date
  description: "Select a date range for analysis"
}

measure: filtered_revenue {
  type: sum
  sql: ${order_total} ;;
  filters: [order_date: "{% parameter date_range %}"]
}
```


In LookML, there are several types of filters that can be applied at different levels (model, explore, and view) to control data access and query behavior. Here's a comprehensive breakdown:

## Model-Level Filters

**Access Filters** - Control data access based on user attributes
```lookml
# In model file
access_grant: sales_team_access {
  allowed_values: ["sales", "manager"]
  user_attribute: department
}

explore: orders {
  access_filter: {
    field: region
    user_attribute: user_region
  }
  # Users only see data for their assigned region
}
```

**Datagroup Filters** - Control when queries refresh based on data changes
```lookml
datagroup: orders_datagroup {
  sql_trigger: SELECT MAX(updated_at) FROM orders ;;
  max_cache_age: "1 hour"
}
```

## Explore-Level Filters

**Always Filters** - Automatically applied to every query, cannot be removed by users
```lookml
explore: orders {
  always_filter: {
    filters: [order_date: "7 days", order_status: "-cancelled"]
  }
  # Every query will only show last 7 days and exclude cancelled orders
}
```

**Conditionally Filters** - Applied based on specific conditions
```lookml
explore: orders {
  conditionally_filter: {
    filters: [order_date: "30 days"]
    unless: [customer_id, order_id]
  }
  # Applies date filter unless user selects specific customer or order
}
```

**SQL Always Where** - Applies raw SQL conditions to every query
```lookml
explore: orders {
  sql_always_where: ${orders.deleted_at} IS NULL 
                   AND ${orders.test_data} = FALSE ;;
  # Excludes deleted records and test data from all queries
}
```

**SQL Always Having** - Applies conditions to aggregated results
```lookml
explore: orders {
  sql_always_having: ${orders.total_revenue} > 0 ;;
  # Only shows results where revenue is positive
}
```

## View-Level Filters

**Dimension Filters** - Built into dimension definitions
```lookml
view: orders {
  dimension: order_status {
    type: string
    sql: ${TABLE}.status ;;
    suggestions: ["pending", "shipped", "delivered"]
  }
  
  dimension: is_recent {
    type: yesno
    sql: ${created_date} >= CURRENT_DATE - 30 ;;
    # Creates a yes/no filter for recent orders
  }
}
```

**Filter-Only Fields** - Create filter inputs without displaying data
```lookml
view: orders {
  filter: date_filter {
    type: date
    description: "Filter orders by date range"
  }
  
  filter: amount_range {
    type: number
    description: "Filter by order amount range"
  }
  
  measure: filtered_revenue {
    type: sum
    sql: ${order_total} ;;
    filters: [
      created_date: "{% parameter date_filter %}",
      order_total: "{% parameter amount_range %}"
    ]
  }
}
```

**Measure Filters** - Applied within measure calculations
```lookml
view: orders {
  measure: new_customer_revenue {
    type: sum
    sql: ${order_total} ;;
    filters: [customers.is_new_customer: "yes"]
  }
  
  measure: high_value_orders {
    type: count
    filters: [order_total: ">100"]
  }
}
```

## Parameter-Based Filters

**Parameters** - User-selectable values that modify queries
```lookml
view: orders {
  parameter: time_period {
    type: unquoted
    allowed_value: {
      label: "Last 7 Days"
      value: "7"
    }
    allowed_value: {
      label: "Last 30 Days" 
      value: "30"
    }
  }
  
  dimension: is_in_period {
    type: yesno
    sql: ${created_date} >= CURRENT_DATE - {% parameter time_period %} ;;
  }
}
```

## Templated Filters

**Liquid Templates** - Dynamic filters using Looker's templating
```lookml
view: orders {
  measure: dynamic_revenue {
    type: sum
    sql: ${order_total} ;;
    filters: [
      created_date: "{% if orders.created_date._in_query %}
                     {% else %}
                     7 days
                     {% endif %}"
    ]
    # Applies default 7-day filter unless user selects specific dates
  }
}
```

## Join-Level Filters

**Join Conditions** - Filters applied during table joins
```lookml
explore: orders {
  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.id} 
            AND ${customers.status} = 'active' ;;
    # Only joins with active customers
  }
}
```

**Relationship Filters** - Control which related records are included
```lookml
explore: customers {
  join: orders {
    type: left_outer
    sql_on: ${customers.id} = ${orders.customer_id} ;;
    sql_where: ${orders.order_date} >= '2023-01-01' ;;
    # Only includes orders from 2023 onwards in the join
  }
}
```

## Security Filters

**User Attribute Filters** - Based on user login attributes
```lookml
view: orders {
  dimension: region {
    type: string
    sql: ${TABLE}.region ;;
  }
}

explore: orders {
  access_filter: {
    field: region
    user_attribute: allowed_regions
  }
  # Users only see data for regions specified in their user attributes
}
```

**Row-Level Security** - Filter data based on user identity
```lookml
explore: orders {
  sql_always_where: 
    CASE 
      WHEN '{{ _user_attributes['department'] }}' = 'sales' 
      THEN ${orders.sales_rep_id} = {{ _user_attributes['employee_id'] }}
      WHEN '{{ _user_attributes['department'] }}' = 'manager'
      THEN 1=1
      ELSE 1=0 
    END ;;
}
```

## Filter Combination Examples

**Complex Multi-Level Filtering**
```lookml
explore: sales_analysis {
  # Model level - always exclude test data
  sql_always_where: ${orders.is_test} = FALSE ;;
  
  # Explore level - default to recent data unless specific filters applied
  conditionally_filter: {
    filters: [orders.created_date: "30 days"]
    unless: [orders.order_id, customers.customer_id]
  }
  
  # Access control - regional data restrictions
  access_filter: {
    field: orders.region
    user_attribute: user_region
  }
  
  join: customers {
    sql_on: ${orders.customer_id} = ${customers.id}
            AND ${customers.status} IN ('active', 'premium') ;;
  }
}
```

These various filter types work together to create secure, performant, and user-friendly data models that automatically apply appropriate constraints while giving users flexibility to explore data within defined boundaries.

----

The key difference between `always_filter` and `sql_always_where` lies in how they apply filters and their flexibility for end users:

## `always_filter`

**User Interface Level** - Works through Looker's filter interface using dimension and measure names
```lookml
explore: orders {
  always_filter: {
    filters: [
      order_date: "7 days",
      order_status: "-cancelled,refunded"
    ]
  }
}
```

**Key Characteristics:**
- Uses LookML field names (dimensions/measures)
- Applied through Looker's filtering system
- **Visible to users** - appears in the filter panel
- **Users can modify values** but cannot remove the filter entirely
- Follows Looker's filter syntax (like "7 days", ">100", "-cancelled")
- More flexible and user-friendly

## `sql_always_where`

**Database Level** - Applies raw SQL conditions directly to the WHERE clause
```lookml
explore: orders {
  sql_always_where: 
    ${orders.created_at} >= CURRENT_DATE - INTERVAL '7 days'
    AND ${orders.status} NOT IN ('cancelled', 'refunded') ;;
}
```

**Key Characteristics:**
- Uses raw SQL with LookML field references (${table.field})
- Applied directly to the generated SQL query
- **Invisible to users** - doesn't appear in filter interface
- **Cannot be modified or removed** by users
- Uses database-specific SQL syntax
- More rigid and secure

## Practical Examples

### `always_filter` Example
```lookml
explore: sales_data {
  always_filter: {
    filters: [
      order_date: "30 days",
      region: "US,Canada"
    ]
  }
}
```
- Users see these filters in the UI
- They can change "30 days" to "90 days" or "2023"
- They can change "US,Canada" to just "US"
- But they cannot remove the date or region filter entirely

### `sql_always_where` Example
```lookml
explore: sales_data {
  sql_always_where: 
    ${orders.deleted_at} IS NULL 
    AND ${orders.is_test_data} = FALSE
    AND ${customers.privacy_opt_out} = FALSE ;;
}
```
- Users never see these conditions
- Automatically excludes deleted records, test data, and privacy opt-outs
- Cannot be overridden by users

## When to Use Each

**Use `always_filter` when:**
- You want to provide default filters that users can adjust
- The filters represent business rules users should be aware of
- You need user-friendly filter interface
- Users might legitimately need different time ranges or categories

```lookml
explore: marketing_campaigns {
  always_filter: {
    filters: [
      campaign_date: "last 3 months",
      campaign_status: "active"
    ]
  }
  # Users can change to "last 6 months" or include "paused" campaigns
}
```

**Use `sql_always_where` when:**
- You need to enforce data security or quality rules
- The conditions should never be modified by users
- You're filtering out system/technical data
- You need complex SQL logic that doesn't translate well to Looker filters

```lookml
explore: customer_orders {
  sql_always_where: 
    ${customers.gdpr_deleted} = FALSE
    AND ${orders.processing_status} != 'failed'
    AND (
      '{{ _user_attributes['department'] }}' = 'admin' 
      OR ${orders.created_at} >= CURRENT_DATE - INTERVAL '2 years'
    ) ;;
  # Security and data quality rules users should never bypass
}
```

## Combined Usage
You can use both together for layered filtering:

```lookml
explore: financial_data {
  # Hard security rule - never visible to users
  sql_always_where: ${transactions.is_internal} = FALSE ;;
  
  # Default business filter - visible and adjustable by users
  always_filter: {
    filters: [transaction_date: "current quarter"]
  }
}
```

In summary: `always_filter` provides **guided flexibility** through the UI, while `sql_always_where` enforces **non-negotiable rules** at the database level.

---

In LookML, dimensions represent attributes or characteristics of your data. Here are all the major types of dimensions with detailed examples:

## Basic Dimension Types

### String Dimensions
For text data and categorical values
```lookml
dimension: customer_name {
  type: string
  sql: ${TABLE}.customer_name ;;
}

dimension: product_category {
  type: string
  sql: ${TABLE}.category ;;
  suggestions: ["Electronics", "Clothing", "Books", "Home & Garden"]
}

dimension: order_status {
  type: string
  sql: ${TABLE}.status ;;
  case: {
    when: {
      sql: ${TABLE}.status = 'shipped' ;;
      label: "Shipped"
    }
    when: {
      sql: ${TABLE}.status = 'pending' ;;
      label: "Pending"
    }
    else: "Other"
  }
}
```

### Number Dimensions
For numeric data that isn't aggregated
```lookml
dimension: customer_id {
  type: number
  primary_key: yes
  sql: ${TABLE}.customer_id ;;
}

dimension: order_total {
  type: number
  sql: ${TABLE}.order_total ;;
  value_format_name: usd
}

dimension: quantity {
  type: number
  sql: ${TABLE}.quantity ;;
}
```

### Yes/No Dimensions
For boolean logic and binary conditions
```lookml
dimension: is_premium_customer {
  type: yesno
  sql: ${customer_lifetime_value} > 1000 ;;
}

dimension: has_discount {
  type: yesno
  sql: ${TABLE}.discount_amount > 0 ;;
}

dimension: is_weekend_order {
  type: yesno
  sql: EXTRACT(DOW FROM ${TABLE}.order_date) IN (0, 6) ;;
}
```

## Date and Time Dimensions

### Date Dimensions
```lookml
dimension: order_date {
  type: date
  sql: ${TABLE}.order_date ;;
}

dimension: birth_date {
  type: date
  sql: ${TABLE}.date_of_birth ;;
  convert_tz: no  # Don't apply timezone conversion
}
```

### Timestamp Dimensions
```lookml
dimension: created_at {
  type: timestamp
  sql: ${TABLE}.created_at ;;
}

dimension: updated_timestamp {
  type: timestamp
  sql: ${TABLE}.last_updated ;;
  convert_tz: yes  # Apply timezone conversion
}
```

### Dimension Groups (Time-based)
Creates multiple related time dimensions from a single field
```lookml
dimension_group: created {
  type: time
  timeframes: [raw, time, date, week, month, quarter, year, day_of_week, hour_of_day]
  sql: ${TABLE}.created_at ;;
}

# This automatically creates:
# - created_raw (original timestamp)
# - created_time (formatted timestamp)
# - created_date (date only)
# - created_week (week starting date)
# - created_month (month)
# - created_quarter (quarter)
# - created_year (year)
# - created_day_of_week (Monday, Tuesday, etc.)
# - created_hour_of_day (0-23)

dimension_group: duration {
  type: duration
  intervals: [day, hour, minute]
  sql_start: ${TABLE}.start_time ;;
  sql_end: ${TABLE}.end_time ;;
}
# Creates duration_days, duration_hours, duration_minutes
```

## Advanced Dimension Types

### Tier Dimensions
For bucketing numeric values into ranges
```lookml
dimension: revenue_tier {
  type: tier
  tiers: [0, 100, 500, 1000, 5000]
  style: integer
  sql: ${TABLE}.order_total ;;
}
# Creates buckets: 0-99, 100-499, 500-999, 1000-4999, 5000+

dimension: age_group {
  type: tier
  tiers: [18, 25, 35, 50, 65]
  style: classic
  sql: EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM ${TABLE}.birth_date) ;;
}
# Creates ranges like "18 to 24", "25 to 34", etc.
```

### Bin Dimensions
For creating equal-width buckets
```lookml
dimension: price_bin {
  type: bin
  bins: [0, 25, 50, 75, 100]
  sql: ${TABLE}.price ;;
}
# Creates bins: [0-25), [25-50), [50-75), [75-100), [100+]
```

### Location Dimensions
For geographic data
```lookml
dimension: location {
  type: location
  sql_latitude: ${TABLE}.latitude ;;
  sql_longitude: ${TABLE}.longitude ;;
}

dimension: zip_code {
  type: zipcode
  sql: ${TABLE}.zip_code ;;
}
```

## Calculated and Conditional Dimensions

### Case Dimensions
For conditional logic
```lookml
dimension: customer_segment {
  type: string
  case: {
    when: {
      sql: ${lifetime_value} >= 10000 ;;
      label: "VIP"
    }
    when: {
      sql: ${lifetime_value} >= 1000 ;;
      label: "Premium"
    }
    when: {
      sql: ${lifetime_value} >= 100 ;;
      label: "Standard"
    }
    else: "Basic"
  }
}

dimension: season {
  type: string
  case: {
    when: {
      sql: EXTRACT(MONTH FROM ${TABLE}.date) IN (12, 1, 2) ;;
      label: "Winter"
    }
    when: {
      sql: EXTRACT(MONTH FROM ${TABLE}.date) IN (3, 4, 5) ;;
      label: "Spring"
    }
    when: {
      sql: EXTRACT(MONTH FROM ${TABLE}.date) IN (6, 7, 8) ;;
      label: "Summer"
    }
    else: "Fall"
  }
}
```

### Concatenated Dimensions
Combining multiple fields
```lookml
dimension: full_name {
  type: string
  sql: CONCAT(${TABLE}.first_name, ' ', ${TABLE}.last_name) ;;
}

dimension: address {
  type: string
  sql: CONCAT(${TABLE}.street, ', ', ${TABLE}.city, ', ', ${TABLE}.state) ;;
}
```

### Mathematical Dimensions
Performing calculations
```lookml
dimension: profit_margin {
  type: number
  sql: (${TABLE}.revenue - ${TABLE}.cost) / ${TABLE}.revenue * 100 ;;
  value_format: "0.00\%"
}

dimension: days_since_last_order {
  type: number
  sql: DATE_DIFF(CURRENT_DATE, ${TABLE}.last_order_date, DAY) ;;
}

dimension: age {
  type: number
  sql: DATE_DIFF(CURRENT_DATE, ${TABLE}.birth_date, YEAR) ;;
}
```

## Special Dimension Properties

### Hidden Dimensions
For internal use only
```lookml
dimension: internal_id {
  type: string
  hidden: yes
  sql: ${TABLE}.internal_reference ;;
}
```

### Primary Key Dimensions
For unique identifiers
```lookml
dimension: order_id {
  type: number
  primary_key: yes
  sql: ${TABLE}.order_id ;;
}
```

### Drill Fields
For interactive exploration
```lookml
dimension: product_category {
  type: string
  sql: ${TABLE}.category ;;
  drill_fields: [product_subcategory, product_name, brand]
}
```

### Link Dimensions
For creating clickable URLs
```lookml
dimension: customer_profile_link {
  type: string
  sql: ${TABLE}.customer_id ;;
  link: {
    label: "View Customer Profile"
    url: "https://crm.company.com/customer/{{ value }}"
  }
}
```

### HTML Dimensions
For rich formatting
```lookml
dimension: status_indicator {
  type: string
  sql: ${TABLE}.status ;;
  html: 
    {% if value == 'Active' %}
      <span style="color: green;">● {{ value }}</span>
    {% elsif value == 'Inactive' %}
      <span style="color: red;">● {{ value }}</span>
    {% else %}
      <span style="color: orange;">● {{ value }}</span>
    {% endif %} ;;
}
```

## Dimension Usage Examples

### Complete Customer Analysis View
```lookml
view: customers {
  dimension: customer_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  dimension: full_name {
    type: string
    sql: CONCAT(${TABLE}.first_name, ' ', ${TABLE}.last_name) ;;
    link: {
      label: "Customer Details"
      url: "/dashboards/customer_detail?customer_id={{ customer_id._value }}"
    }
  }
  
  dimension_group: registered {
    type: time
    timeframes: [date, week, month, year]
    sql: ${TABLE}.registration_date ;;
  }
  
  dimension: customer_tier {
    type: tier
    tiers: [0, 500, 1000, 5000]
    style: integer
    sql: ${lifetime_value} ;;
  }
  
  dimension: is_active {
    type: yesno
    sql: ${TABLE}.last_login_date >= CURRENT_DATE - 30 ;;
  }
  
  dimension: geography {
    type: string
    map_layer_name: us_states
    sql: ${TABLE}.state ;;
  }
}
```

These dimension types provide the building blocks for creating rich, interactive data models that allow users to slice, dice, and explore data from multiple perspectives while maintaining proper data types and formatting.

---

Here are comprehensive examples of using variables and field chaining in LookML to create reusable, DRY (Don't Repeat Yourself) code:

## 1. Using Variables for Reusable SQL Snippets

### Defining Variables in Models
```lookml
# ecommerce_model.model
connection: "ecommerce_db"

# Define reusable variables
variable: current_period_filter {
  default_value: "7"
}

variable: revenue_calculation {
  default_value: "quantity * unit_price - COALESCE(discount_amount, 0)"
}

variable: customer_tier_logic {
  default_value: """
    CASE 
      WHEN lifetime_value >= 10000 THEN 'VIP'
      WHEN lifetime_value >= 1000 THEN 'Premium'
      WHEN lifetime_value >= 100 THEN 'Standard'
      ELSE 'Basic'
    END
  """
}
```

### Using Variables in Views
```lookml
view: orders {
  sql_table_name: public.orders ;;
  
  dimension: order_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  # Using variable for consistent revenue calculation
  dimension: net_revenue {
    type: number
    sql: @{revenue_calculation} ;;
    value_format_name: usd
  }
  
  # Using variable in filters and measures
  measure: current_period_revenue {
    type: sum
    sql: @{revenue_calculation} ;;
    filters: [created_date: "@{current_period_filter} days"]
    value_format_name: usd
  }
  
  measure: total_revenue {
    type: sum
    sql: @{revenue_calculation} ;;
    value_format_name: usd
  }
}

view: customers {
  sql_table_name: public.customers ;;
  
  # Using the same customer tier logic across multiple views
  dimension: customer_tier {
    type: string
    sql: @{customer_tier_logic} ;;
  }
  
  # Chain this dimension in other calculations
  dimension: is_high_value {
    type: yesno
    sql: @{customer_tier_logic} IN ('VIP', 'Premium') ;;
  }
}
```

## 2. Field Chaining and References

### Basic Field Chaining
```lookml
view: sales_analysis {
  sql_table_name: public.orders ;;
  
  # Base dimensions
  dimension: order_total {
    type: number
    sql: ${TABLE}.order_total ;;
  }
  
  dimension: quantity {
    type: number
    sql: ${TABLE}.quantity ;;
  }
  
  # Chain fields together for calculations
  dimension: unit_price {
    type: number
    sql: ${order_total} / NULLIF(${quantity}, 0) ;;
    value_format_name: usd
  }
  
  dimension: is_bulk_order {
    type: yesno
    sql: ${quantity} >= 10 ;;
  }
  
  dimension: order_size_category {
    type: string
    sql: 
      CASE 
        WHEN ${quantity} >= 50 THEN 'Bulk'
        WHEN ${quantity} >= 10 THEN 'Large'
        WHEN ${quantity} >= 5 THEN 'Medium'
        ELSE 'Small'
      END ;;
  }
  
  # Chain the category in measures
  measure: bulk_order_revenue {
    type: sum
    sql: ${order_total} ;;
    filters: [is_bulk_order: "yes"]
  }
  
  measure: average_unit_price_by_category {
    type: average
    sql: ${unit_price} ;;
    drill_fields: [order_size_category, quantity, unit_price]
  }
}
```

### Advanced Field Chaining with Date Logic
```lookml
view: time_analysis {
  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, quarter, year, day_of_week]
    sql: ${TABLE}.created_at ;;
  }
  
  # Chain date dimensions for complex logic
  dimension: is_weekend {
    type: yesno
    sql: ${created_day_of_week} IN ('Saturday', 'Sunday') ;;
  }
  
  dimension: is_current_month {
    type: yesno
    sql: ${created_month} = EXTRACT(MONTH FROM CURRENT_DATE) 
         AND ${created_year} = EXTRACT(YEAR FROM CURRENT_DATE) ;;
  }
  
  dimension: days_since_created {
    type: number
    sql: DATE_DIFF(CURRENT_DATE, ${created_date}, DAY) ;;
  }
  
  # Chain multiple time-based dimensions
  dimension: recency_category {
    type: string
    sql: 
      CASE 
        WHEN ${days_since_created} <= 7 THEN 'This Week'
        WHEN ${days_since_created} <= 30 THEN 'This Month'
        WHEN ${days_since_created} <= 90 THEN 'This Quarter'
        ELSE 'Older'
      END ;;
  }
  
  # Use chained fields in measures
  measure: weekend_orders {
    type: count
    filters: [is_weekend: "yes"]
  }
  
  measure: recent_orders_pct {
    type: number
    sql: 
      100.0 * SUM(CASE WHEN ${days_since_created} <= 30 THEN 1 ELSE 0 END) / 
      COUNT(*) ;;
    value_format: "0.0\%"
  }
}
```

## 3. Cross-View Field Chaining

### Customer Lifetime Value Chain
```lookml
view: customers {
  dimension: customer_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  dimension: registration_date {
    type: date
    sql: ${TABLE}.created_at ;;
  }
  
  dimension: customer_age_days {
    type: number
    sql: DATE_DIFF(CURRENT_DATE, ${registration_date}, DAY) ;;
  }
  
  # This will be referenced from orders view
  dimension: customer_tier {
    type: string
    sql: @{customer_tier_logic} ;;
  }
}

view: orders {
  dimension: customer_id {
    type: number
    sql: ${TABLE}.customer_id ;;
  }
  
  dimension: order_total {
    type: number
    sql: ${TABLE}.total_amount ;;
  }
  
  # Chain customer fields in orders context
  measure: revenue_by_tier {
    type: sum
    sql: ${order_total} ;;
    drill_fields: [customers.customer_tier, customers.customer_id, order_total]
  }
  
  measure: avg_order_value_new_customers {
    type: average
    sql: ${order_total} ;;
    filters: [customers.customer_age_days: "<=30"]
  }
}
```

## 4. Parameterized Reusable Logic

### Dynamic Time Period Analysis
```lookml
view: flexible_analytics {
  parameter: time_granularity {
    type: unquoted
    allowed_value: {
      label: "Day"
      value: "day"
    }
    allowed_value: {
      label: "Week"
      value: "week"
    }
    allowed_value: {
      label: "Month"
      value: "month"
    }
    default_value: "day"
  }
  
  parameter: comparison_period {
    type: number
    default_value: "30"
  }
  
  # Chain parameters with dimensions
  dimension: dynamic_time_dimension {
    type: string
    sql: 
      {% if time_granularity._parameter_value == 'day' %}
        ${created_date}
      {% elsif time_granularity._parameter_value == 'week' %}
        ${created_week}
      {% else %}
        ${created_month}
      {% endif %} ;;
  }
  
  dimension: is_comparison_period {
    type: yesno
    sql: 
      ${created_date} >= CURRENT_DATE - {% parameter comparison_period %} ;;
  }
  
  # Chain these in measures
  measure: flexible_revenue {
    type: sum
    sql: ${order_total} ;;
    filters: [is_comparison_period: "yes"]
  }
}
```

## 5. Complex Chaining Example: E-commerce Analytics

### Comprehensive Product Performance View
```lookml
view: product_performance {
  # Base product dimensions
  dimension: product_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.product_id ;;
  }
  
  dimension: category {
    type: string
    sql: ${TABLE}.category ;;
  }
  
  dimension: price {
    type: number
    sql: ${TABLE}.price ;;
  }
  
  # Chain pricing tiers
  dimension: price_tier {
    type: tier
    tiers: [0, 25, 50, 100, 200]
    style: integer
    sql: ${price} ;;
  }
  
  dimension: is_premium_product {
    type: yesno
    sql: ${price_tier} = "200 or Above" ;;
  }
  
  # Sales performance dimensions (chained from other fields)
  dimension: total_quantity_sold {
    type: number
    sql: 
      (SELECT SUM(quantity) 
       FROM order_items oi 
       WHERE oi.product_id = ${product_id}) ;;
  }
  
  dimension: total_revenue {
    type: number
    sql: 
      (SELECT SUM(quantity * unit_price) 
       FROM order_items oi 
       WHERE oi.product_id = ${product_id}) ;;
  }
  
  # Chain multiple fields for performance categories
  dimension: performance_score {
    type: number
    sql: 
      CASE 
        WHEN ${total_quantity_sold} = 0 THEN 0
        ELSE ${total_revenue} / ${total_quantity_sold} 
      END ;;
  }
  
  dimension: performance_category {
    type: string
    sql: 
      CASE 
        WHEN ${total_quantity_sold} = 0 THEN 'No Sales'
        WHEN ${performance_score} >= 100 AND ${total_quantity_sold} >= 50 THEN 'Star Performer'
        WHEN ${performance_score} >= 75 OR ${total_quantity_sold} >= 100 THEN 'Good Performer'
        WHEN ${performance_score} >= 50 OR ${total_quantity_sold} >= 25 THEN 'Average'
        ELSE 'Poor Performer'
      END ;;
  }
  
  # Measures that chain all the logic together
  measure: products_by_performance {
    type: count
    drill_fields: [category, performance_category, price_tier, total_revenue]
  }
  
  measure: revenue_from_star_products {
    type: sum
    sql: ${total_revenue} ;;
    filters: [performance_category: "Star Performer"]
  }
  
  measure: avg_price_by_performance {
    type: average
    sql: ${price} ;;
    drill_fields: [performance_category, category, price]
  }
}
```

## 6. Variable-Based Join Logic

### Reusable Join Patterns
```lookml
# In model file
variable: standard_date_join {
  default_value: """
    ${orders.created_date} = ${daily_summary.summary_date}
  """
}

variable: customer_join_condition {
  default_value: """
    ${orders.customer_id} = ${customers.id} 
    AND ${customers.status} = 'active'
  """
}

explore: orders {
  join: customers {
    type: left_outer
    sql_on: @{customer_join_condition} ;;
  }
  
  join: daily_summary {
    type: left_outer
    sql_on: @{standard_date_join} ;;
  }
}

explore: customer_analysis {
  join: customers {
    type: inner
    sql_on: @{customer_join_condition} ;;
  }
}
```

These patterns demonstrate how variables and field chaining create maintainable, reusable LookML code where business logic is defined once and referenced throughout your model, making updates and consistency much easier to manage.

----

In LookML, there are three fundamental types of measures based on how they handle data aggregation. Here's a detailed explanation with examples:

## 1. Aggregate Measures

Aggregate measures perform SQL aggregation functions on raw data. They are the most common type and process data at the database level before returning results to Looker.

### Basic Aggregate Functions

**Count Measures**
```lookml
measure: total_orders {
  type: count
  # Counts all rows in the result set
  drill_fields: [order_id, customer_name, order_date]
}

measure: unique_customers {
  type: count_distinct
  sql: ${customer_id} ;;
  # Counts distinct customer IDs
}
```

**Sum Measures**
```lookml
measure: total_revenue {
  type: sum
  sql: ${order_total} ;;
  value_format_name: usd
}

measure: total_quantity_sold {
  type: sum
  sql: ${quantity} ;;
  # Sums up all quantity values
}
```

**Average Measures**
```lookml
measure: average_order_value {
  type: average
  sql: ${order_total} ;;
  value_format_name: usd_0
}

measure: avg_customer_age {
  type: average
  sql: ${customer_age} ;;
  value_format: "0.0"
}
```

**Min/Max Measures**
```lookml
measure: first_order_date {
  type: min
  sql: ${order_date} ;;
}

measure: highest_order_value {
  type: max
  sql: ${order_total} ;;
  value_format_name: usd
}
```

**Advanced Aggregate Measures**
```lookml
measure: median_order_value {
  type: median
  sql: ${order_total} ;;
  value_format_name: usd
}

measure: revenue_percentile_90 {
  type: percentile
  percentile: 90
  sql: ${order_total} ;;
}

measure: standard_deviation_order_size {
  type: stddev_pop
  sql: ${order_total} ;;
}
```

## 2. Non-Aggregate Measures

Non-aggregate measures don't perform SQL aggregation. They either return single values or perform calculations on already-aggregated data.

### Table Calculations (Non-SQL)
```lookml
measure: conversion_rate {
  type: number
  sql: 1.0 * ${orders_count} / NULLIF(${website_visits}, 0) ;;
  value_format_name: percent_2
  # This calculates a rate from two aggregate measures
}

measure: revenue_per_customer {
  type: number
  sql: 1.0 * ${total_revenue} / NULLIF(${customer_count}, 0) ;;
  value_format_name: usd
  # Division of two aggregated values
}
```

### List and String Aggregations
```lookml
measure: customer_list {
  type: list
  list_field: customer_name
  # Returns a comma-separated list of customer names
}

measure: top_products {
  type: string
  sql: STRING_AGG(${product_name}, ', ') ;;
  # Concatenates product names (database-specific function)
}
```

### Single Value Measures
```lookml
measure: current_date_display {
  type: string
  sql: CURRENT_DATE() ;;
  # Returns current date, no aggregation needed
}

measure: company_name {
  type: string
  sql: 'Acme Corporation' ;;
  # Static value
}
```

### Ratio Measures (Non-aggregate calculations)
```lookml
measure: profit_margin_percent {
  type: number
  sql: 
    CASE 
      WHEN ${total_revenue} > 0 
      THEN 100.0 * (${total_revenue} - ${total_cost}) / ${total_revenue}
      ELSE 0 
    END ;;
  value_format: "0.00\%"
  # Calculates percentage from aggregate measures
}
```

## 3. Post-SQL Measures (Table Calculations)

Post-SQL measures are calculated after the SQL query returns data to Looker. They operate on the aggregated results and are useful for complex calculations that can't be done efficiently in SQL.

### Running Totals and Window Functions
```lookml
measure: running_total_revenue {
  type: running_total
  sql: ${total_revenue} ;;
  # Calculates cumulative sum across sorted results
}

measure: revenue_rank {
  type: rank
  sql: ${total_revenue} ;;
  # Ranks results by revenue (1 = highest)
}

measure: revenue_percent_of_total {
  type: percent_of_total
  sql: ${total_revenue} ;;
  # Each row's percentage of the total
}
```

### Period-over-Period Calculations
```lookml
measure: revenue_previous_period {
  type: number
  sql: ${total_revenue} ;;
  # This would be used with table calculations for period comparisons
}

# In explore, you'd add table calculations like:
# table_calculation: revenue_growth {
#   expression: (${total_revenue} - offset(${total_revenue}, 1)) / offset(${total_revenue}, 1) ;;
#   value_format_name: percent_1
# }
```

## Complex Examples Combining All Types

### E-commerce Performance Dashboard
```lookml
view: ecommerce_metrics {
  
  # AGGREGATE MEASURES
  measure: total_orders {
    type: count
    filters: [order_status: "-cancelled"]
  }
  
  measure: total_revenue {
    type: sum
    sql: ${order_total} ;;
    value_format_name: usd
  }
  
  measure: unique_customers {
    type: count_distinct
    sql: ${customer_id} ;;
  }
  
  measure: avg_order_value {
    type: average
    sql: ${order_total} ;;
    value_format_name: usd_0
  }
  
  # NON-AGGREGATE MEASURES
  measure: revenue_per_customer {
    type: number
    sql: 1.0 * ${total_revenue} / NULLIF(${unique_customers}, 0) ;;
    value_format_name: usd
  }
  
  measure: order_frequency {
    type: number
    sql: 1.0 * ${total_orders} / NULLIF(${unique_customers}, 0) ;;
    value_format: "0.00"
  }
  
  measure: top_customers_list {
    type: list
    list_field: customer_name
    order_by_field: total_revenue
    # Shows list of customers ordered by revenue
  }
  
  # POST-SQL MEASURES (used in explores)
  measure: revenue_running_total {
    type: running_total
    sql: ${total_revenue} ;;
  }
  
  measure: customer_rank_by_revenue {
    type: rank
    sql: ${revenue_per_customer} ;;
  }
  
  measure: revenue_percentile {
    type: percent_of_total
    sql: ${total_revenue} ;;
  }
}
```

### Financial Analysis Example
```lookml
view: financial_metrics {
  
  # AGGREGATE - Raw data aggregation
  measure: gross_revenue {
    type: sum
    sql: ${TABLE}.revenue ;;
    value_format_name: usd
  }
  
  measure: total_costs {
    type: sum
    sql: ${TABLE}.operating_costs + ${TABLE}.marketing_costs ;;
    value_format_name: usd
  }
  
  measure: transaction_count {
    type: count
    filters: [transaction_type: "sale"]
  }
  
  # NON-AGGREGATE - Calculations on aggregated data
  measure: net_profit {
    type: number
    sql: ${gross_revenue} - ${total_costs} ;;
    value_format_name: usd
  }
  
  measure: profit_margin {
    type: number
    sql: 
      CASE 
        WHEN ${gross_revenue} > 0 
        THEN 100.0 * ${net_profit} / ${gross_revenue}
        ELSE 0 
      END ;;
    value_format: "0.00\%"
  }
  
  measure: cost_per_transaction {
    type: number
    sql: 1.0 * ${total_costs} / NULLIF(${transaction_count}, 0) ;;
    value_format_name: usd
  }
  
  # POST-SQL - Applied after query execution
  measure: profit_running_total {
    type: running_total
    sql: ${net_profit} ;;
  }
  
  measure: monthly_profit_rank {
    type: rank
    sql: ${net_profit} ;;
  }
}
```

## Key Differences Summary

| Aspect | Aggregate | Non-Aggregate | Post-SQL |
|--------|-----------|---------------|----------|
| **Processing** | Database level | Database level | Looker application level |
| **Data Input** | Raw rows | Already aggregated data | Query results |
| **Performance** | Fast (database optimized) | Fast | Slower (client-side) |
| **SQL Generation** | Uses GROUP BY | Simple calculations | Applied after main query |
| **Use Cases** | Summing, counting, averaging raw data | Ratios, rates between aggregates | Running totals, rankings, percentages of total |
| **Limitations** | None | Can't aggregate raw data | Limited by result set size |

Understanding these three types helps you choose the right measure type for optimal performance and accurate calculations in your LookML models.

---

In LookML, **Group Labels** and **View Labels** are organizational tools that help create cleaner, more user-friendly interfaces by categorizing and customizing how fields and views appear to end users.

## Group Labels

Group labels organize related fields within a view into logical categories, making it easier for users to find and understand fields in the field picker.

### Basic Group Label Syntax
```lookml
view: customers {
  # Personal Information Group
  dimension: first_name {
    type: string
    sql: ${TABLE}.first_name ;;
    group_label: "Personal Information"
  }
  
  dimension: last_name {
    type: string
    sql: ${TABLE}.last_name ;;
    group_label: "Personal Information"
  }
  
  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
    group_label: "Contact Details"
  }
  
  dimension: phone {
    type: string
    sql: ${TABLE}.phone ;;
    group_label: "Contact Details"
  }
  
  # Financial Metrics Group
  dimension: lifetime_value {
    type: number
    sql: ${TABLE}.lifetime_value ;;
    group_label: "Financial Metrics"
    value_format_name: usd
  }
  
  measure: total_spent {
    type: sum
    sql: ${TABLE}.total_spent ;;
    group_label: "Financial Metrics"
    value_format_name: usd
  }
}
```

### E-commerce Example with Multiple Group Labels
```lookml
view: orders {
  # ORDER DETAILS GROUP
  dimension: order_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
    group_label: "Order Details"
  }
  
  dimension: order_status {
    type: string
    sql: ${TABLE}.status ;;
    group_label: "Order Details"
  }
  
  dimension: order_source {
    type: string
    sql: ${TABLE}.source ;;
    group_label: "Order Details"
  }
  
  # TIMING GROUP
  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
    group_label: "Timing"
  }
  
  dimension_group: shipped {
    type: time
    timeframes: [date, week, month]
    sql: ${TABLE}.shipped_at ;;
    group_label: "Timing"
  }
  
  # FINANCIAL GROUP
  dimension: order_total {
    type: number
    sql: ${TABLE}.total_amount ;;
    group_label: "Financial"
    value_format_name: usd
  }
  
  dimension: discount_amount {
    type: number
    sql: ${TABLE}.discount ;;
    group_label: "Financial"
    value_format_name: usd
  }
  
  measure: total_revenue {
    type: sum
    sql: ${order_total} ;;
    group_label: "Financial"
    value_format_name: usd
  }
  
  measure: average_order_value {
    type: average
    sql: ${order_total} ;;
    group_label: "Financial"
    value_format_name: usd
  }
  
  # GEOGRAPHIC GROUP
  dimension: shipping_city {
    type: string
    sql: ${TABLE}.shipping_city ;;
    group_label: "Geographic"
  }
  
  dimension: shipping_state {
    type: string
    sql: ${TABLE}.shipping_state ;;
    group_label: "Geographic"
  }
  
  dimension: shipping_country {
    type: string
    sql: ${TABLE}.shipping_country ;;
    group_label: "Geographic"
  }
}
```

## View Labels

View labels customize how view names appear to end users in the field picker and throughout the Looker interface, making them more business-friendly.

### Basic View Label Syntax
```lookml
view: dim_customers {
  # Technical table name is dim_customers, but users see "Customers"
  view_label: "Customers"
  sql_table_name: warehouse.dim_customers ;;
  
  dimension: customer_id {
    type: number
    sql: ${TABLE}.id ;;
  }
}

view: fact_orders {
  view_label: "Orders"  # Users see "Orders" instead of "fact_orders"
  sql_table_name: warehouse.fact_orders ;;
  
  dimension: order_id {
    type: number
    sql: ${TABLE}.id ;;
  }
}
```

### Complex Example with View Labels in Explores
```lookml
# Model file with explores
explore: sales_analysis {
  view_name: fact_orders
  view_label: "Sales Data"  # Override the view's own label for this explore
  
  join: dim_customers {
    view_label: "Customer Information"  # Override default "Customers" label
    type: left_outer
    sql_on: ${fact_orders.customer_id} = ${dim_customers.customer_id} ;;
  }
  
  join: dim_products {
    view_label: "Product Catalog"
    type: left_outer
    sql_on: ${fact_orders.product_id} = ${dim_products.product_id} ;;
  }
  
  join: geography_lookup {
    view_label: "Geographic Data"  # Much cleaner than "geography_lookup"
    type: left_outer
    sql_on: ${dim_customers.zip_code} = ${geography_lookup.zip} ;;
  }
}
```

## Advanced Combinations: Group Labels + View Labels

### Comprehensive Analytics Dashboard Example
```lookml
view: customer_analytics {
  view_label: "Customer Analytics"
  sql_table_name: analytics.customer_summary ;;
  
  # IDENTIFICATION GROUP
  dimension: customer_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.customer_id ;;
    group_label: "Identification"
  }
  
  dimension: customer_name {
    type: string
    sql: ${TABLE}.full_name ;;
    group_label: "Identification"
  }
  
  dimension: customer_segment {
    type: string
    sql: ${TABLE}.segment ;;
    group_label: "Identification"
  }
  
  # DEMOGRAPHICS GROUP
  dimension: age_group {
    type: string
    sql: ${TABLE}.age_bracket ;;
    group_label: "Demographics"
  }
  
  dimension: gender {
    type: string
    sql: ${TABLE}.gender ;;
    group_label: "Demographics"
  }
  
  dimension: income_level {
    type: string
    sql: ${TABLE}.income_tier ;;
    group_label: "Demographics"
  }
  
  # BEHAVIORAL METRICS GROUP
  dimension: total_orders {
    type: number
    sql: ${TABLE}.order_count ;;
    group_label: "Behavioral Metrics"
  }
  
  dimension: days_since_last_order {
    type: number
    sql: ${TABLE}.days_since_last_purchase ;;
    group_label: "Behavioral Metrics"
  }
  
  measure: avg_time_between_orders {
    type: average
    sql: ${TABLE}.avg_days_between_orders ;;
    group_label: "Behavioral Metrics"
    value_format: "0.0"
  }
  
  # FINANCIAL PERFORMANCE GROUP
  dimension: lifetime_value {
    type: number
    sql: ${TABLE}.clv ;;
    group_label: "Financial Performance"
    value_format_name: usd
  }
  
  measure: total_customer_value {
    type: sum
    sql: ${lifetime_value} ;;
    group_label: "Financial Performance"
    value_format_name: usd
  }
  
  measure: average_customer_value {
    type: average
    sql: ${lifetime_value} ;;
    group_label: "Financial Performance"
    value_format_name: usd
  }
  
  # ENGAGEMENT METRICS GROUP
  dimension: email_opens_last_month {
    type: number
    sql: ${TABLE}.recent_email_opens ;;
    group_label: "Engagement Metrics"
  }
  
  dimension: website_visits_last_month {
    type: number
    sql: ${TABLE}.recent_web_visits ;;
    group_label: "Engagement Metrics"
  }
  
  measure: engagement_score {
    type: average
    sql: ${TABLE}.engagement_score ;;
    group_label: "Engagement Metrics"
    value_format: "0.00"
  }
}
```

### Multi-View Explore with Organized Labels
```lookml
explore: comprehensive_sales {
  view_name: orders
  view_label: "Order Transactions"
  
  join: customers {
    view_label: "Customer Profiles"
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.id} ;;
  }
  
  join: products {
    view_label: "Product Information"
    type: left_outer
    sql_on: ${orders.product_id} = ${products.id} ;;
  }
  
  join: marketing_campaigns {
    view_label: "Marketing Attribution"
    type: left_outer
    sql_on: ${orders.campaign_id} = ${marketing_campaigns.id} ;;
  }
}

# Each view has its own group labels
view: products {
  view_label: "Product Information"  # This can be overridden in explore
  
  dimension: product_name {
    type: string
    sql: ${TABLE}.name ;;
    group_label: "Basic Info"
  }
  
  dimension: category {
    type: string
    sql: ${TABLE}.category ;;
    group_label: "Classification"
  }
  
  dimension: subcategory {
    type: string
    sql: ${TABLE}.subcategory ;;
    group_label: "Classification"
  }
  
  dimension: price {
    type: number
    sql: ${TABLE}.price ;;
    group_label: "Pricing"
    value_format_name: usd
  }
  
  dimension: cost {
    type: number
    sql: ${TABLE}.cost ;;
    group_label: "Pricing"
    value_format_name: usd
  }
}
```

## User Interface Impact

When properly implemented, group labels and view labels create a much cleaner interface:

**Without Labels:**
- Fields appear as: `dim_customers.cust_first_nm`, `fact_orders.ord_tot_amt`
- All fields in flat list
- Technical table names visible

**With Labels:**
- Views appear as: "Customer Profiles", "Order Transactions"
- Fields organized under: "Personal Information", "Financial Metrics", "Geographic Data"
- Business-friendly names throughout

## Best Practices

### Group Label Organization
```lookml
# Use consistent group naming across views
group_label: "Basic Information"     # Not "Basic Info" elsewhere
group_label: "Financial Metrics"    # Not "Finance" elsewhere
group_label: "Geographic Data"      # Not "Geography" elsewhere

# Keep group names short but descriptive
group_label: "Timing"               # Good
group_label: "Date and Time Information"  # Too long

# Use logical groupings
group_label: "Contact Details"      # email, phone, address
group_label: "Demographics"         # age, gender, income
group_label: "Behavioral Metrics"   # orders, visits, engagement
```

### View Label Strategy
```lookml
# Make view labels business-friendly
view_label: "Customers"             # Not "dim_customers"
view_label: "Sales Transactions"    # Not "fact_sales_trans"
view_label: "Product Catalog"       # Not "prod_dim_tbl"

# Be consistent across explores
view_label: "Customer Data"         # Use same label everywhere
view_label: "Order Information"     # Consistent naming pattern
```

These organizational tools significantly improve the user experience by making complex data models more intuitive and business-user friendly.

---

In LookML, join parameters control how views are connected and how the resulting data is queried. Here are the most commonly used join parameters with detailed examples:

## 1. Basic Join Parameters

### `type` - Specifies the SQL join type
```lookml
explore: orders {
  join: customers {
    type: left_outer  # Most common - keeps all orders even without customer data
    sql_on: ${orders.customer_id} = ${customers.id} ;;
  }
  
  join: order_items {
    type: inner  # Only orders that have items
    sql_on: ${orders.id} = ${order_items.order_id} ;;
  }
  
  join: promotions {
    type: right_outer  # Less common - keeps all promotions
    sql_on: ${orders.promo_code} = ${promotions.code} ;;
  }
  
  join: inventory {
    type: full_outer  # Rare - keeps all records from both sides
    sql_on: ${order_items.product_id} = ${inventory.product_id} ;;
  }
  
  join: product_reviews {
    type: cross  # Cartesian product - rarely used
    sql_on: ${orders.product_id} = ${product_reviews.product_id} ;;
  }
}
```

### `sql_on` - Defines the join condition
```lookml
explore: orders {
  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.id} ;;
  }
  
  # Complex join condition
  join: customer_addresses {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customer_addresses.customer_id} 
            AND ${customer_addresses.address_type} = 'shipping'
            AND ${customer_addresses.is_active} = true ;;
  }
  
  # Date-based join
  join: daily_exchange_rates {
    type: left_outer
    sql_on: DATE(${orders.created_date}) = ${daily_exchange_rates.rate_date}
            AND ${orders.currency} = ${daily_exchange_rates.currency_code} ;;
  }
}
```

## 2. Relationship Parameters

### `relationship` - Defines the data relationship type
```lookml
explore: customers {
  join: orders {
    type: left_outer
    relationship: one_to_many  # One customer can have many orders
    sql_on: ${customers.id} = ${orders.customer_id} ;;
  }
  
  join: customer_profile {
    type: left_outer
    relationship: one_to_one  # Each customer has one profile
    sql_on: ${customers.id} = ${customer_profile.customer_id} ;;
  }
  
  join: product_categories {
    type: left_outer
    relationship: many_to_one  # Many products belong to one category
    sql_on: ${orders.product_id} = ${product_categories.product_id} ;;
  }
  
  join: order_tags {
    type: left_outer
    relationship: many_to_many  # Orders can have multiple tags, tags can apply to multiple orders
    sql_on: ${orders.id} = ${order_tags.order_id} ;;
  }
}
```

## 3. Field Selection Parameters

### `fields` - Controls which fields are available from the joined view
```lookml
explore: orders {
  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.id} ;;
    fields: [customers.name, customers.email, customers.customer_tier, customers.total_orders]
    # Only these specific fields are available, not all customer fields
  }
  
  join: products {
    type: left_outer
    sql_on: ${orders.product_id} = ${products.id} ;;
    fields: [products.basic_info*, products.pricing*]
    # Include all fields from specific field groups
  }
  
  join: internal_metrics {
    type: left_outer
    sql_on: ${orders.id} = ${internal_metrics.order_id} ;;
    fields: []  # No fields exposed to users (join used for filtering only)
  }
}
```

## 4. Performance and Behavior Parameters

### `sql_always_where` - Applies additional WHERE conditions to the joined view
```lookml
explore: orders {
  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.id} ;;
    sql_always_where: ${customers.status} = 'active' 
                     AND ${customers.deleted_at} IS NULL ;;
    # Only join with active, non-deleted customers
  }
  
  join: order_items {
    type: left_outer
    sql_on: ${orders.id} = ${order_items.order_id} ;;
    sql_always_where: ${order_items.quantity} > 0 
                     AND ${order_items.unit_price} > 0 ;;
    # Filter out invalid order items
  }
}
```

### `sql_where` - Dynamic WHERE conditions based on query context
```lookml
explore: orders {
  join: seasonal_promotions {
    type: left_outer
    sql_on: ${orders.promo_code} = ${seasonal_promotions.code} ;;
    sql_where: 
      {% if orders.created_date._in_query %}
        ${seasonal_promotions.valid_from} <= ${orders.created_date} 
        AND ${seasonal_promotions.valid_to} >= ${orders.created_date}
      {% else %}
        ${seasonal_promotions.is_currently_active} = true
      {% endif %} ;;
  }
}
```

## 5. Scope and Access Parameters

### `view_label` - Overrides the view's label in this specific join context
```lookml
explore: customer_analysis {
  join: orders {
    type: left_outer
    view_label: "Purchase History"  # Instead of "Orders"
    sql_on: ${customers.id} = ${orders.customer_id} ;;
  }
  
  join: orders as recent_orders {
    type: left_outer
    view_label: "Recent Purchases"
    sql_on: ${customers.id} = ${recent_orders.customer_id} ;;
    sql_always_where: ${recent_orders.created_date} >= CURRENT_DATE - 30 ;;
  }
}
```

### `required_access_grants` - Controls access to joined data
```lookml
# Define access grant in model
access_grant: pii_access {
  allowed_values: ["admin", "manager"]
  user_attribute: security_level
}

explore: orders {
  join: customer_pii {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customer_pii.customer_id} ;;
    required_access_grants: [pii_access]
    # Only users with proper access can see this joined data
  }
}
```

## 6. Advanced Join Scenarios

### Multiple Joins with Dependencies
```lookml
explore: comprehensive_sales {
  # Primary customer join
  join: customers {
    type: left_outer
    relationship: many_to_one
    sql_on: ${orders.customer_id} = ${customers.id} ;;
  }
  
  # Customer address depends on customer join
  join: customer_addresses {
    type: left_outer
    relationship: one_to_one
    sql_on: ${customers.id} = ${customer_addresses.customer_id} ;;
    sql_always_where: ${customer_addresses.address_type} = 'primary' ;;
  }
  
  # Geographic data depends on address
  join: zip_code_data {
    type: left_outer
    relationship: many_to_one
    sql_on: ${customer_addresses.zip_code} = ${zip_code_data.zip} ;;
    fields: [zip_code_data.city, zip_code_data.state, zip_code_data.region]
  }
  
  # Product information
  join: products {
    type: left_outer
    relationship: many_to_one
    sql_on: ${orders.product_id} = ${products.id} ;;
  }
  
  # Product category depends on product
  join: categories {
    type: left_outer
    relationship: many_to_one
    sql_on: ${products.category_id} = ${categories.id} ;;
    view_label: "Product Categories"
  }
}
```

### Self-Joins with Aliases
```lookml
explore: employee_hierarchy {
  view_name: employees
  
  # Join employees to their managers
  join: managers {
    from: employees  # Same view, different alias
    type: left_outer
    relationship: many_to_one
    sql_on: ${employees.manager_id} = ${managers.employee_id} ;;
    view_label: "Manager Information"
    fields: [managers.name, managers.title, managers.department]
  }
  
  # Join to department head (another level up)
  join: department_heads {
    from: employees
    type: left_outer
    relationship: many_to_one
    sql_on: ${managers.manager_id} = ${department_heads.employee_id} ;;
    view_label: "Department Leadership"
  }
}
```

### Conditional Joins
```lookml
explore: dynamic_product_analysis {
  join: product_reviews {
    type: left_outer
    sql_on: ${products.id} = ${product_reviews.product_id} ;;
    sql_where: 
      {% if _user_attributes['show_reviews'] == 'yes' %}
        ${product_reviews.is_verified} = true
      {% else %}
        1 = 0  -- Effectively disable the join
      {% endif %} ;;
  }
  
  join: competitor_pricing {
    type: left_outer
    sql_on: ${products.sku} = ${competitor_pricing.sku} ;;
    required_access_grants: [pricing_access]
    sql_always_where: ${competitor_pricing.data_date} >= CURRENT_DATE - 7 ;;
  }
}
```

## 7. Performance Optimization Examples

### Indexed Join Optimization
```lookml
explore: high_volume_orders {
  join: customers {
    type: left_outer
    relationship: many_to_one
    sql_on: ${orders.customer_id} = ${customers.id} ;;
    # Ensure customer_id is indexed in both tables
  }
  
  join: order_summary {
    type: left_outer
    relationship: one_to_one
    sql_on: ${orders.id} = ${order_summary.order_id} ;;
    # Pre-aggregated summary table for performance
  }
  
  join: customer_segments {
    type: left_outer
    relationship: many_to_one
    sql_on: ${customers.segment_id} = ${customer_segments.id} ;;
    sql_always_where: ${customer_segments.is_active} = true ;;
    # Filter inactive segments at join time
  }
}
```

### Fan-out Control
```lookml
explore: customer_orders {
  join: order_items {
    type: left_outer
    relationship: one_to_many
    sql_on: ${orders.id} = ${order_items.order_id} ;;
    # Be careful with one-to-many joins - they can cause fan-out
  }
  
  # Use aggregate tables to avoid fan-out issues
  join: order_totals {
    type: left_outer
    relationship: one_to_one
    sql_on: ${orders.id} = ${order_totals.order_id} ;;
    # Pre-aggregated totals prevent double-counting
  }
}
```

These join parameters provide precise control over how data is combined, ensuring accurate results while optimizing performance and maintaining security. The key is choosing the right combination based on your data relationships and business requirements.

---

In LookML, `extends` is a powerful inheritance mechanism that allows you to create new views or explores based on existing ones, inheriting their properties while adding, modifying, or overriding specific elements. This promotes code reusability and maintainability.

## View Extensions

### Basic View Extension
```lookml
# Base view
view: base_customers {
  sql_table_name: public.customers ;;
  
  dimension: customer_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  dimension: name {
    type: string
    sql: ${TABLE}.full_name ;;
  }
  
  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
  }
  
  dimension: created_date {
    type: date
    sql: ${TABLE}.created_at ;;
  }
  
  measure: customer_count {
    type: count
  }
}

# Extended view - inherits all fields from base_customers
view: customers {
  extends: [base_customers]
  
  # Add new fields
  dimension: customer_tier {
    type: string
    sql: 
      CASE 
        WHEN ${lifetime_value} >= 10000 THEN 'VIP'
        WHEN ${lifetime_value} >= 1000 THEN 'Premium'
        ELSE 'Standard'
      END ;;
  }
  
  dimension: lifetime_value {
    type: number
    sql: ${TABLE}.total_spent ;;
    value_format_name: usd
  }
  
  # Override inherited field
  dimension: name {
    type: string
    sql: UPPER(${TABLE}.full_name) ;;  # Override to show uppercase names
    label: "Customer Name (Upper Case)"
  }
  
  # Add new measures
  measure: average_lifetime_value {
    type: average
    sql: ${lifetime_value} ;;
    value_format_name: usd
  }
}
```

### Multiple Inheritance
```lookml
# Base demographic fields
view: demographic_base {
  dimension: age_group {
    type: string
    sql: 
      CASE 
        WHEN ${age} < 25 THEN '18-24'
        WHEN ${age} < 35 THEN '25-34'
        WHEN ${age} < 50 THEN '35-49'
        ELSE '50+'
      END ;;
  }
  
  dimension: age {
    type: number
    sql: EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM ${birth_date}) ;;
  }
}

# Base geographic fields
view: geographic_base {
  dimension: region {
    type: string
    sql: 
      CASE 
        WHEN ${state} IN ('CA', 'OR', 'WA') THEN 'West Coast'
        WHEN ${state} IN ('NY', 'NJ', 'CT') THEN 'Northeast'
        WHEN ${state} IN ('TX', 'FL', 'GA') THEN 'South'
        ELSE 'Other'
      END ;;
  }
  
  dimension: state {
    type: string
    sql: ${TABLE}.state ;;
  }
}

# Extended view inheriting from multiple parents
view: customer_profile {
  extends: [base_customers, demographic_base, geographic_base]
  
  dimension: birth_date {
    type: date
    sql: ${TABLE}.date_of_birth ;;
  }
  
  # Now has access to all fields from all three parent views
  dimension: customer_summary {
    type: string
    sql: CONCAT(${name}, ' - ', ${age_group}, ' - ', ${region}) ;;
  }
}
```

## Explore Extensions

### Basic Explore Extension
```lookml
# Base explore
explore: base_sales {
  view_name: orders
  
  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.id} ;;
  }
  
  join: products {
    type: left_outer
    sql_on: ${orders.product_id} = ${products.id} ;;
  }
}

# Extended explore - inherits all joins and configurations
explore: sales_analysis {
  extends: [base_sales]
  
  # Add additional joins
  join: customer_segments {
    type: left_outer
    sql_on: ${customers.segment_id} = ${customer_segments.id} ;;
  }
  
  join: promotions {
    type: left_outer
    sql_on: ${orders.promo_code} = ${promotions.code} ;;
  }
  
  # Override inherited join
  join: customers {
    type: inner  # Change from left_outer to inner
    sql_on: ${orders.customer_id} = ${customers.id} ;;
    sql_always_where: ${customers.status} = 'active' ;;  # Add filter
  }
  
  # Add explore-level filters
  always_filter: {
    filters: [orders.created_date: "30 days"]
  }
}
```

### Conditional Extensions
```lookml
# Base explore for general sales analysis
explore: sales_base {
  view_name: orders
  
  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.id} ;;
  }
  
  join: products {
    type: left_outer
    sql_on: ${orders.product_id} = ${products.id} ;;
  }
}

# Executive dashboard - simplified view
explore: executive_sales {
  extends: [sales_base]
  label: "Executive Sales Dashboard"
  
  # Hide detailed fields, show only high-level metrics
  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.id} ;;
    fields: [customers.customer_tier, customers.region, customers.customer_count]
  }
  
  join: products {
    type: left_outer
    sql_on: ${orders.product_id} = ${products.id} ;;
    fields: [products.category, products.brand, products.total_revenue]
  }
  
  # Add executive-specific filters
  sql_always_where: ${orders.order_total} > 0 ;;
}

# Detailed analysis for analysts
explore: detailed_sales {
  extends: [sales_base]
  label: "Detailed Sales Analysis"
  
  # Add more detailed joins
  join: order_items {
    type: left_outer
    sql_on: ${orders.id} = ${order_items.order_id} ;;
  }
  
  join: inventory {
    type: left_outer
    sql_on: ${products.sku} = ${inventory.sku} ;;
  }
  
  join: sales_reps {
    type: left_outer
    sql_on: ${orders.sales_rep_id} = ${sales_reps.id} ;;
  }
}
```

## Real-World Examples

### Multi-Tenant Application
```lookml
# Base view for multi-tenant data
view: tenant_base {
  dimension: tenant_id {
    type: string
    sql: ${TABLE}.tenant_id ;;
    hidden: yes  # Hide from users but use in filters
  }
  
  # Automatic tenant filtering
  sql_always_where: ${tenant_id} = '{{ _user_attributes['tenant_id'] }}' ;;
}

# Customer view with tenant filtering
view: customers {
  extends: [tenant_base]
  sql_table_name: customers ;;
  
  dimension: customer_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }
  
  # Inherits tenant_id and filtering automatically
}

# Orders view with tenant filtering
view: orders {
  extends: [tenant_base]
  sql_table_name: orders ;;
  
  dimension: order_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  dimension: order_total {
    type: number
    sql: ${TABLE}.total ;;
  }
  
  # Also inherits tenant filtering
}
```

### Environment-Specific Extensions
```lookml
# Base production view
view: production_orders {
  sql_table_name: prod.orders ;;
  
  dimension: order_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  dimension: order_total {
    type: number
    sql: ${TABLE}.amount ;;
  }
  
  measure: total_revenue {
    type: sum
    sql: ${order_total} ;;
  }
}

# Development environment extension
view: dev_orders {
  extends: [production_orders]
  sql_table_name: dev.orders ;;  # Different table
  
  # Add debugging fields only available in dev
  dimension: debug_info {
    type: string
    sql: ${TABLE}.debug_data ;;
    hidden: no  # Visible in dev environment
  }
  
  dimension: test_flag {
    type: yesno
    sql: ${TABLE}.is_test_data ;;
  }
  
  # Override measure to exclude test data
  measure: total_revenue {
    type: sum
    sql: ${order_total} ;;
    filters: [test_flag: "no"]
  }
}
```

### Role-Based View Extensions
```lookml
# Base customer view
view: customer_base {
  sql_table_name: customers ;;
  
  dimension: customer_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  dimension: name {
    type: string
    sql: ${TABLE}.full_name ;;
  }
  
  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
  }
}

# Sales team view - can see contact info
view: customers_sales {
  extends: [customer_base]
  view_label: "Customers (Sales View)"
  
  dimension: phone {
    type: string
    sql: ${TABLE}.phone ;;
  }
  
  dimension: sales_notes {
    type: string
    sql: ${TABLE}.notes ;;
  }
  
  measure: qualified_leads {
    type: count
    filters: [lead_status: "qualified"]
  }
}

# Marketing team view - can see campaign data
view: customers_marketing {
  extends: [customer_base]
  view_label: "Customers (Marketing View)"
  
  dimension: email_opt_in {
    type: yesno
    sql: ${TABLE}.email_marketing_consent ;;
  }
  
  dimension: last_campaign {
    type: string
    sql: ${TABLE}.last_campaign_id ;;
  }
  
  measure: email_subscribers {
    type: count
    filters: [email_opt_in: "yes"]
  }
}

# Public/limited view - minimal information
view: customers_public {
  extends: [customer_base]
  view_label: "Customer Summary"
  
  # Override to hide sensitive info
  dimension: email {
    type: string
    sql: 'HIDDEN' ;;  # Don't show actual email
  }
  
  # Add aggregated, non-sensitive data
  dimension: customer_since_year {
    type: string
    sql: EXTRACT(YEAR FROM ${TABLE}.created_at) ;;
  }
}
```

## Advanced Extension Patterns

### Template Pattern
```lookml
# Template for financial metrics
view: financial_metrics_template {
  measure: total_revenue {
    type: sum
    sql: ${revenue_field} ;;
    value_format_name: usd
  }
  
  measure: average_revenue {
    type: average
    sql: ${revenue_field} ;;
    value_format_name: usd
  }
  
  measure: revenue_rank {
    type: rank
    sql: ${total_revenue} ;;
  }
}

# Specific implementation
view: product_financials {
  extends: [financial_metrics_template]
  sql_table_name: product_sales ;;
  
  # Define the revenue_field referenced in template
  dimension: revenue_field {
    type: number
    sql: ${TABLE}.product_revenue ;;
    hidden: yes
  }
  
  dimension: product_id {
    type: number
    sql: ${TABLE}.product_id ;;
  }
  
  # Inherits all financial measures
}
```

### Override and Extension Chain
```lookml
# Level 1: Base
view: base_entity {
  dimension: id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
  
  dimension: name {
    type: string
    sql: ${TABLE}.name ;;
  }
}

# Level 2: Add common business logic
view: business_entity {
  extends: [base_entity]
  
  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }
  
  dimension: is_active {
    type: yesno
    sql: ${status} = 'active' ;;
  }
}

# Level 3: Specific implementation
view: customers {
  extends: [business_entity]
  sql_table_name: customers ;;
  
  dimension: customer_type {
    type: string
    sql: ${TABLE}.type ;;
  }
  
  # Override name to include customer type
  dimension: name {
    type: string
    sql: CONCAT(${TABLE}.name, ' (', ${customer_type}, ')') ;;
  }
}
```

## Best Practices

### Organizing Extensions
```lookml
# Keep base views in separate files for clarity
# _base_views.view (underscore prefix indicates it's a base)

# Use descriptive extend names
extends: [customer_base, demographic_mixin, security_filters]

# Document what each extension adds
view: enhanced_customers {
  extends: [customer_base]  # Basic customer fields
  # Extensions add: demographic analysis, security filtering, and marketing metrics
  
  # New fields here...
}
```

### Performance Considerations
```lookml
# Base view optimized for performance
view: optimized_base {
  sql_table_name: 
    (SELECT * FROM large_table 
     WHERE created_date >= CURRENT_DATE - 90) ;;  # Pre-filter for performance
  
  dimension: id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
  }
}

# Extended views inherit the optimization
view: recent_data_analysis {
  extends: [optimized_base]
  
  # All queries automatically include the 90-day filter
  measure: recent_count {
    type: count
  }
}
```

Extensions in LookML provide powerful inheritance capabilities that promote code reuse, maintainability, and consistency across your data model while allowing for customization and specialization where needed.

---

In LookML, tests and assertions are data quality validation mechanisms that help ensure your data model produces accurate, consistent results. They're essential for maintaining data integrity and catching issues early in the development process.

## Types of Tests in LookML

### 1. Data Tests
Data tests validate the actual data returned by your queries and measures.

#### Basic Data Tests
```lookml
view: customers {
  sql_table_name: public.customers ;;
  
  dimension: customer_id {
    type: number
    primary_key: yes
    sql: ${TABLE}.id ;;
    
    # Test that customer_id is never null
    test: customer_id_not_null {
      explore_source: customers {
        column: customer_id {}
        filters: [
          customers.customer_id: "NULL"
        ]
      }
      assert: customer_id_not_null {
        expression: ${customers.count} = 0 ;;
        # Should return 0 rows with null customer_id
      }
    }
  }
  
  dimension: email {
    type: string
    sql: ${TABLE}.email ;;
    
    # Test email format validation
    test: valid_email_format {
      explore_source: customers {
        column: email {}
        column: count {}
        filters: [
          customers.email: "-%@%.%"  # Invalid email pattern
        ]
      }
      assert: no_invalid_emails {
        expression: ${customers.count} = 0 ;;
      }
    }
  }
  
  measure: count {
    type: count
  }
}
```

#### Revenue Validation Tests
```lookml
view: orders {
  sql_table_name: public.orders ;;
  
  dimension: order_total {
    type: number
    sql: ${TABLE}.order_total ;;
  }
  
  measure: total_revenue {
    type: sum
    sql: ${order_total} ;;
    value_format_name: usd
  }
  
  measure: count {
    type: count
  }
  
  # Test that revenue is always positive
  test: revenue_positive {
    explore_source: orders {
      column: total_revenue {}
      filters: [
        orders.order_total: "<0"
      ]
    }
    assert: no_negative_revenue {
      expression: ${orders.total_revenue} = 0 ;;
      # Sum of negative orders should be 0 (no negative orders exist)
    }
  }
  
  # Test that order totals match line item sums
  test: order_total_consistency {
    explore_source: orders {
      column: order_id {}
      column: order_total {}
      column: calculated_total {
        field: order_line_items.line_total
      }
    }
    assert: totals_match {
      expression: ${orders.order_total} = ${order_line_items.line_total} ;;
    }
  }
}
```

### 2. Relationship Tests
Test the integrity of joins and relationships between tables.

```lookml
explore: orders {
  join: customers {
    type: left_outer
    sql_on: ${orders.customer_id} = ${customers.customer_id} ;;
  }
  
  # Test referential integrity
  test: customer_referential_integrity {
    explore_source: orders {
      column: customer_id {}
      column: count {}
      filters: [
        customers.customer_id: "NULL"  # Orders without matching customers
      ]
    }
    assert: all_orders_have_customers {
      expression: ${orders.count} = 0 ;;
      # Should be 0 orders without matching customers
    }
  }
  
  # Test for duplicate relationships
  test: no_duplicate_customers {
    explore_source: customers {
      column: customer_id {}
      column: count {}
      having: [
        customers.count: ">1"
      ]
    }
    assert: unique_customer_ids {
      expression: ${customers.count} = 0 ;;
      # Should be 0 duplicate customer IDs
    }
  }
}
```

### 3. Business Logic Tests
Validate complex business rules and calculations.

```lookml
view: sales_metrics {
  
  dimension: order_date {
    type: date
    sql: ${TABLE}.order_date ;;
  }
  
  dimension: order_total {
    type: number
    sql: ${TABLE}.order_total ;;
  }
  
  measure: total_revenue {
    type: sum
    sql: ${order_total} ;;
  }
  
  measure: order_count {
    type: count
  }
  
  measure: average_order_value {
    type: number
    sql: ${total_revenue} / NULLIF(${order_count}, 0) ;;
  }
  
  # Test business rule: AOV calculation
  test: aov_calculation_accuracy {
    explore_source: sales_metrics {
      column: total_revenue {}
      column: order_count {}
      column: average_order_value {}
      filters: [
        sales_metrics.order_date: "7 days"
      ]
    }
    assert: aov_matches_manual_calculation {
      expression: 
        ABS(${sales_metrics.average_order_value} - 
            (${sales_metrics.total_revenue} / ${sales_metrics.order_count})) < 0.01 ;;
      # AOV should match manual calculation within 1 cent
    }
  }
  
  # Test seasonal business rule
  test: q4_revenue_boost {
    explore_source: sales_metrics {
      column: order_date { field: sales_metrics.order_month }
      column: total_revenue {}
    }
    assert: q4_higher_than_q3 {
      expression: 
        {% assign q4_revenue = 0 %}
        {% assign q3_revenue = 0 %}
        {% for row in query_result %}
          {% assign month = row['sales_metrics.order_month'] | date: '%m' %}
          {% if month >= '10' %}
            {% assign q4_revenue = q4_revenue | plus: row['sales_metrics.total_revenue'] %}
          {% elsif month >= '07' and month <= '09' %}
            {% assign q3_revenue = q3_revenue | plus: row['sales_metrics.total_revenue'] %}
          {% endif %}
        {% endfor %}
        {{ q4_revenue }} > {{ q3_revenue }} ;;
    }
  }
}
```

### 4. Dimension Group Tests
Test time-based logic and dimension groups.

```lookml
view: time_analysis {
  
  dimension_group: created {
    type: time
    timeframes: [raw, date, week, month, quarter, year]
    sql: ${TABLE}.created_at ;;
  }
  
  dimension: is_weekend {
    type: yesno
    sql: EXTRACT(DOW FROM ${created_date}) IN (0, 6) ;;
  }
  
  measure: count {
    type: count
  }
  
  # Test weekend logic
  test: weekend_classification {
    explore_source: time_analysis {
      column: created_day_of_week {}
      column: is_weekend {}
      column: count {}
    }
    assert: saturday_sunday_are_weekend {
      expression: 
        {% for row in query_result %}
          {% assign dow = row['time_analysis.created_day_of_week'] %}
          {% assign is_weekend = row['time_analysis.is_weekend'] %}
          {% if dow == 'Saturday' or dow == 'Sunday' %}
            {% unless is_weekend == 'Yes' %}
              false
              {% break %}
            {% endunless %}
          {% else %}
            {% if is_weekend == 'Yes' %}
              false
              {% break %}
            {% endif %}
          {% endif %}
        {% endfor %}
        true ;;
    }
  }
  
  # Test date consistency
  test: date_timeframes_consistency {
    explore_source: time_analysis {
      column: created_date {}
      column: created_month {}
      column: created_year {}
    }
    assert: date_parts_match {
      expression: 
        EXTRACT(MONTH FROM ${time_analysis.created_date}) = EXTRACT(MONTH FROM ${time_analysis.created_month})
        AND EXTRACT(YEAR FROM ${time_analysis.created_date}) = ${time_analysis.created_year} ;;
    }
  }
}
```

## Advanced Testing Patterns

### 5. Cross-View Consistency Tests
```lookml
# Test data consistency across different views
test: customer_order_consistency {
  explore_source: orders {
    column: customer_count { field: customers.count }
    join: [customers]
  }
  
  explore_source: customers {
    column: customer_count { field: customers.count }
  }
  
  assert: customer_counts_match {
    expression: 
      ${orders.customer_count} = ${customers.customer_count} ;;
    # Customer count should be same in both contexts
  }
}

# Test aggregate consistency
test: revenue_aggregation_consistency {
  explore_source: orders {
    column: total_revenue {}
  }
  
  explore_source: daily_revenue_summary {
    column: sum_daily_revenue { field: daily_revenue_summary.total_revenue }
  }
  
  assert: daily_sum_equals_order_sum {
    expression: 
      ABS(${orders.total_revenue} - ${daily_revenue_summary.sum_daily_revenue}) < 1.00 ;;
    # Daily aggregates should sum to order total within $1
  }
}
```

### 6. Performance and Data Volume Tests
```lookml
view: performance_monitoring {
  
  measure: row_count {
    type: count
  }
  
  measure: distinct_customers {
    type: count_distinct
    sql: ${customer_id} ;;
  }
  
  # Test for unexpected data volume changes
  test: data_volume_stability {
    explore_source: performance_monitoring {
      column: row_count {}
      filters: [
        performance_monitoring.created_date: "yesterday"
      ]
    }
    assert: reasonable_daily_volume {
      expression: 
        ${performance_monitoring.row_count} > 1000 
        AND ${performance_monitoring.row_count} < 100000 ;;
      # Daily volume should be between 1K and 100K rows
    }
  }
  
  # Test for data freshness
  test: data_freshness {
    explore_source: performance_monitoring {
      column: max_date { field: performance_monitoring.created_date }
    }
    assert: data_is_recent {
      expression: 
        DATE_DIFF(CURRENT_DATE, ${performance_monitoring.max_date}, DAY) <= 1 ;;
      # Data should be no more than 1 day old
    }
  }
}
```

### 7. User Attribute and Security Tests
```lookml
# Test row-level security
test: user_security_filtering {
  explore_source: orders {
    column: count {}
    filters: [
      # Simulate user with specific attributes
      orders.region: "{% if _user_attributes['region'] == 'US' %}US{% else %}International{% endif %}"
    ]
  }
  
  assert: proper_data_filtering {
    expression: 
      {% if _user_attributes['region'] == 'US' %}
        ${orders.count} > 0  # US users should see US data
      {% else %}
        ${orders.count} >= 0  # International users see international data
      {% endif %} ;;
  }
}
```

## Test Execution and Monitoring

### 8. Comprehensive Test Suite
```lookml
# Master test view combining multiple test categories
view: data_quality_tests {
  
  # Data integrity tests
  test: primary_key_uniqueness {
    explore_source: customers {
      column: customer_id {}
      column: count {}
      having: [customers.count: ">1"]
    }
    assert: no_duplicate_primary_keys {
      expression: ${customers.count} = 0 ;;
    }
  }
  
  # Business rule tests
  test: customer_lifecycle_logic {
    explore_source: customers {
      column: registration_date { field: customers.created_date }
      column: first_order_date { field: orders.min_order_date }
      join: [orders]
    }
    assert: first_order_after_registration {
      expression: ${orders.min_order_date} >= ${customers.created_date} ;;
    }
  }
  
  # Performance tests
  test: query_performance {
    explore_source: orders {
      column: total_revenue {}
      column: count {}
      filters: [orders.created_date: "30 days"]
    }
    assert: reasonable_response_time {
      # This would be monitored externally, but structure is here
      expression: true ;;  # Placeholder for performance monitoring
    }
  }
}
```

### 9. Test Documentation and Maintenance
```lookml
view: documented_tests {
  
  # Well-documented test with clear purpose
  test: order_status_completeness {
    # PURPOSE: Ensure all orders have valid status values
    # BUSINESS IMPACT: Invalid statuses can break reporting dashboards
    # FREQUENCY: Run daily
    # OWNER: Data Engineering Team
    
    explore_source: orders {
      column: count {}
      filters: [
        orders.order_status: "NULL,-shipped,-pending,-cancelled,-delivered"
      ]
    }
    
    assert: all_orders_have_valid_status {
      expression: ${orders.count} = 0 ;;
      # Zero orders should have invalid or null status
    }
  }
}
```

## Best Practices for Testing

### 10. Modular Testing Approach
```lookml
# Separate test files for different domains
# _customer_tests.view
view: customer_tests {
  test: customer_email_validity { ... }
  test: customer_uniqueness { ... }
}

# _financial_tests.view  
view: financial_tests {
  test: revenue_consistency { ... }
  test: pricing_validation { ... }
}

# _integration_tests.view
view: integration_tests {
  test: cross_table_consistency { ... }
  test: data_pipeline_integrity { ... }
}
```

Tests and assertions in LookML provide a robust framework for ensuring data quality, business rule compliance, and model accuracy. They serve as early warning systems for data issues and help maintain confidence in your analytics platform as it scales and evolves.
