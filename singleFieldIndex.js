// Single Field Index
// Create an index on the `name` field
db.collection("myCollection").createIndex({ name: 1 });

// View all indexes
db.collection("myCollection").getIndexes();
