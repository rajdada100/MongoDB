// Wildcard Index
// Create a wildcard index for all fields
db.collection("myCollection").createIndex({ "$**": 1 });

// View all indexes
db.collection("myCollection").getIndexes();
