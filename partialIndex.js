// Partial Index
// Create a partial index on the `status` field, including only documents where `status` is `active`
db.collection("myCollection").createIndex(
  { status: 1 },
  { partialFilterExpression: { status: "active" } }
);

// View all indexes
db.collection("myCollection").getIndexes();

// Use Case Example
// This index will optimize queries like the one below:
db.collection("myCollection").find({ status: "active" });

// Another Example: Partial Index for Specific Field Range
// Index only documents where `age` is greater than or equal to 18
db.collection("myCollection").createIndex(
  { age: 1 },
  { partialFilterExpression: { age: { $gte: 18 } } }
);

// Use Case Example
// Queries like this will use the partial index:
db.collection("myCollection").find({ age: { $gte: 18 } });
