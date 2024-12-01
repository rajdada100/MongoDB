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



