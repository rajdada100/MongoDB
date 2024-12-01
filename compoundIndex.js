// Compound Index
// Create an index on the `firstName` and `lastName` fields
db.collection("myCollection").createIndex({ firstName: 1, lastName: -1 });

// View all indexes
db.collection("myCollection").getIndexes();
