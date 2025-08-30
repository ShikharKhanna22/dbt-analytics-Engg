

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
