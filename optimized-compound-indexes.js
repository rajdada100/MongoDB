# Code Summary: Optimized Compound Indexes

The code in this example uses some sample documents that you can insert into your MongoDB instance or Atlas Cluster with the following command in `mongosh`:


db.getSiblingDB("sample_game").users.insertMany([
  {
    _id: new ObjectId("6488bcfe84b99e26917f78b1"),
    dob: new Date("1987"),
    username: "testAccount",
    inactive: false,
    score: 800,
  },
  {
    _id: new ObjectId("6488bcfe84b99e26917f78b2"),
    dob: new Date("1988"),
    username: "exampleUser",
    inactive: false,
    score: 700,
  },
  {
    _id: new ObjectId("6488bcfe84b99e26917f78b3"),
    dob: new Date("1989"),
    username: "coolperson",
    inactive: true,
    score: 998,
  },
  {
    _id: new ObjectId("6488bcfe84b99e26917f78b4"),
    dob: new Date("1990"),
    username: "randomGuy",
    inactive: false,
    score: 500,
  },
]);


To get a sorted list of current scores, for active users born between 1988 and 1990 sorted by current score in descending order, the following query was used:


db.users.find(
  { dob: { $gte: new Date("1988"), $lte: new Date("1990") }, inactive: false },
  { username: 1, score: 1 }
).sort({ score: -1 });

To arrive at the optimal index, break down the query into smaller parts, starting with the range fields. The resulting query will find users born between 1988 and 1990:

db.users.find({ dob: { $gte: new Date("1988"), $lte: new Date("1990") }

To see how the range query performs before any indexes are created, use the explain method in executionStats mode on the range query. To return only the executionStats object from the output, use the following command:

db.users.find({
  dob:{ $gte: new Date("1988"), $lte: new Date("1990")
}}).explain('executionStats').executionStats

To create an index to support the range query, use the following command to create an index on the dob field:

db.users.createIndex({ dob: 1 })

To test query performance after creating the index, run the following command to get only the executionStats object once again:

db.users.find({
  dob:{ $gte: new Date("1988"), $lte: new Date("1990")
}}).explain('executionStats').executionStats

To test out the next part of the query, add an equality check to filter out inactive users and return the executionStats from the explain output, like so:

db.users.find({
  dob: { $gte: new Date("1988"), $lte: new Date("1990") }, inactive: false
}).explain('executionStats').executionStats

To support the equality plus range query, create a compound index on the dob and inactive fields, like so:

db.users.createIndex({ dob: 1, inactive: 1})

To test the query after creating the compound index, run the following command once again. Notice that MongoDB doesn’t choose the dob-inactive index on its own.

db.users.find({
  dob: { $gte: new Date("1988"), $lte: new Date("1990") }, inactive: false
}).explain('executionStats').executionStats

To force MongoDB to use the compound index, use the hint method on the query itself, like so:

db.users.find({
  dob: { $gte: new Date("1988"), $lte: new Date("1990") },
  inactive: false,
}).hint({
  dob: 1, inactive: 1
}).explain("executionStats").executionStats

To try and improve the performance of the query, create a new compound index with the order of the fields reversed, such that the equality field (inactive) comes before the range field (dob):

db.users.createIndex({ inactive: 1, dob: 1})

To examine how the the inactive-dob index performs, get the executionStats from the explain output for the equality plus range query:

db.users.find({
  dob: { $gte: new Date("1988"), $lte: new Date("1990") },
  inactive: false,
}).explain("executionStats").executionStats

To examine how a query with all three fields (equality, sort, and range) performs with the current indexes, add the sort condition back to the query and return the executionStats from the explain output using the following command.

db.users.find({
  dob: { $gte: new Date("1988"), $lte: new Date("1990") },
  inactive: false,
}).sort({ current_score: -1 }).explain("executionStats").executionStats

To resolve the problem of the in-memory sort, create a compound index on the equality (inactive) and sort fields (current_score):

db.users.createIndex({ inactive: 1, current_score: 1 })

Test the inactive-current score index by getting the executionStats from the explain output, like so:

db.users.explain("executionStats").find({
  dob: { $gte: new Date("1988"), $lte: new Date("1990") },
  inactive: false,
}).sort({ current_score: -1 })

To further optimize the query, add the dob field to the index using the following command:

db.users.createIndex({ inactive: 1, current_score: 1, dob: 1 })

To ensure the new index is used, add the hint method to the query and return the executionStats from the explain output, like so:

db.users.explain("executionStats").find({
  dob: { $gte: new Date("1988"), $lte: new Date("1990") },
  inactive: false,
}).sort({ current_score: -1 }).hint({ inactive: 1, current_score: 1, dob: 1 })

The inactive, current_score, dob index has outperformed the others, leading us to the conclusion that the optimal order for indexes is to put equality fields first (in any order), followed by range fields, and sort fields behind both equality and range.

