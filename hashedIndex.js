// Hashed Index
// Create a hashed index on the `userId` field
db.collection("myCollection").createIndex({ userId: "hashed" });

// View all indexes
db.collection("myCollection").getIndexes();
