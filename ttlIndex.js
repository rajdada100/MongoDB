// TTL Index
// Create a TTL index on the `createdAt` field with a 3600-second expiration
db.collection("myCollection").createIndex(
  { createdAt: 1 },
  { expireAfterSeconds: 3600 }
);

// View all indexes
db.collection("myCollection").getIndexes();
