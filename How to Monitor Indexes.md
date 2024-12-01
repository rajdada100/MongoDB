# How to Monitor Indexes in MongoDB

MongoDB provides the db.collection.aggregate method with $indexStats to monitor index usage.
To use the $indexStats aggregation operator to return statistics regarding the use of each index for the collection, use the aggregate method on the collection.

## 1. **List All Indexes**
To view all indexes on a collection, use the following command:
```javascript
db.collection.getIndexes();
```
Analyze Index Usage
MongoDB provides a way to track index usage statistics using the $indexStats aggregation stage.
```javascript
db.collection.aggregate([{ $indexStats: {} }]);
```
Output Example:
The result shows:
* accesses.ops: Number of operations using the index.
* accesses.since: Timestamp of when the index statistics were last reset.
  
```json
[
  {
    "name": "email_1",
    "key": { "email": 1 },
    "accesses": { "ops": 150, "since": "2024-01-01T00:00:00Z" }
  }
]
```

Monitor Index Size
To check the storage size of indexes on a collection, use the stats method:
```javascript
db.collection.stats();
```
Relevant Field:
* totalIndexSize: Total size of all indexes in bytes.
* indexSizes: Size of each index individually.

Use explain to Verify Index Usage
The explain() method helps determine whether a query is using an index.
Command:
```javascript
db.collection.find({ email: "example@example.com" }).explain("executionStats");
```
Output Highlights:
* **stage: "IXSCAN"`: Indicates an index scan was used.
* indexName: Name of the index used.

Monitor Index Building (Index Creation)
For index creation in progress, you can use:
```javascript
db.currentOp({ "msg": { $regex: /Index Build/ } });
```

Remove Unused Indexes
To identify and remove unused indexes:
1. Use $indexStats to check accesses.ops for low or zero usage.
2. Drop the index
```javascript
db.collection.dropIndex("index_name");
```
   
