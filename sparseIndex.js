Sparse Indexes in MongoDB are designed to index only documents that contain the indexed field, omitting documents where the field is null or absent. 
They are useful for saving storage space and improving query performance when fields are not uniformly present in all documents.

// Sparse Index
// Create a sparse index on the `email` field
db.collection("myCollection").createIndex(
  { email: 1 },
  { sparse: true }
);

// View all indexes
db.collection("myCollection").getIndexes();

// Use Case Example
// Documents where `email` is not present will be excluded from the index
// This index will optimize queries like the one below:
db.collection("myCollection").find({ email: "example@example.com" });

// Compound Sparse Index Example
// Create a sparse index on both `email` and `phone` fields
db.collection("myCollection").createIndex(
  { email: 1, phone: 1 },
  { sparse: true }
);

// Notes:
// 1. Sparse indexes only include documents that contain all fields specified in the index.
// 2. Sparse indexes are ignored if the query contains a null or missing value for the indexed field.

// Querying for a document where the `email` is absent won't use the sparse index:
db.collection("myCollection").find({ email: { $exists: false } });

How Sparse Indexes Work

Sparse indexes exclude documents where the indexed field is either null or does not exist.
They are beneficial when you have optional fields that are not present in all documents.

