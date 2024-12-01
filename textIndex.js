// Text Index
// Create a text index on the `description` field
db.collection("myCollection").createIndex({ description: "text" });

// View all indexes
db.collection("myCollection").getIndexes();

// Search using the text index
db.collection("myCollection").find({ $text: { $search: "example" } });
