#  Using the MongoDB Shell Library (.mongoshrc.js)

The `.mongoshrc.js` file can be used to run code when `mongosh` starts. This file doesn’t exist unless you create it. To create the file, run the following command in your home directory:

```bash
touch ~/.mongoshrc.js

The db.adminCommand() is used to run administrative commands against the admin database, which we can write helper functions for and then add them directly to the .mongoshrc.js file.
For example, the following code shows a lengthy command to get the server’s compatibility version wrapped in a helper function called fcv().
This function is added to the global scope of mongosh by adding the function directly to the .mongoshrc.js file:

const fcv = () => db.adminCommand({ getParameter: 1, featureCompatibilityVersion: 1 });

We can also use the .mongoshrc.js file to customize the prompt. For example, we can customize the prompt to display information about the current mongosh session by using the prompt() function.
For example, the following code displays the database name, the current user, and the read preference in the prompt:

prompt = () => {
    let returnString = "";
    const dbName = db.getName();
    const isEnterprise = db.serverBuildInfo().modules.includes("enterprise");
    const mongoURL = db.getMongo()._uri.includes("mongodb.net");
    const nonAtlasEnterprise = isEnterprise && !mongoURL;
    const usingAtlas = mongoURL && isEnterprise;
    const readPref = db.getMongo().getReadPrefMode();
    const isLocalHost = /localhost|127\.0\.0\.1/.test(db.getMongo()._uri);
    const currentUser = db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers[0]?.user;

    if (usingAtlas) {
        returnString += `Atlas || ${dbName} || ${currentUser} || ${readPref} || =>`;
    } else if (isLocalHost) {
        returnString += `${nonAtlasEnterprise ? "Enterprise || localhost" : "localhost"} || ${dbName} || ${readPref} || =>`;
    } else if (nonAtlasEnterprise) {
        returnString += `Enterprise || ${dbName} || ${currentUser} || ${readPref} || =>`;
    } else {
        returnString += `${dbName} || ${readPref} || =>`;
    }

    return returnString;
};


---

### Steps to Save This on GitHub:
1. **Save the file locally**:
   - Use an appropriate file name like `mongoshrc.md` if you want Markdown rendering or `mongoshrc.js` if it's for code execution.

2. **Add it to GitHub**:
   - Upload the file to your repository and commit it.
   - If saved as `.md`, GitHub will render it as a well-formatted document.

Let me know if you need further adjustments!
