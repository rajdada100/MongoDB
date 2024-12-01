// Multikey Index
// Create an index on the `tags` field which contains arrays
db.collection("myCollection").createIndex({ tags: 1 });

// View all indexes
db.collection("myCollection").getIndexes();
