/* code from functions/todos-create.js */
const { Octokit } = require("@octokit/rest");
const octokit = new Octokit({
  auth: process.env.GITHUB_ACCESS_TOKEN,
})

/* export our lambda function as named "handler" export */
exports.handler = (event, context, callback) => {
  if (!event.headers["authorization"] || event.headers["authorization"] != "Bearer " + process.env.TOKEN){
    return callback(null, {
      statusCode: 401,
      body: "{}"
    })
  }

  if (event.httpMethod === 'GET') {
    return callback(null, {
      statusCode: 200,
      body: "{}"
    })
  }

  /* parse the string body into a useable JS object */
  const data = JSON.parse(event.body)
  console.log("Data: ", data);
  const title = data["properties"]["name"][0]
  const content = data["properties"]["content"][0]
  const date = new Date()
  const filename = [date.toISOString().split('T')[0], title.replace(/[\W]+/g,"-")].join("-")
  var fileContent = []

  // If we've written a post without fontmatter, insert default forntmatter
  if (!content.includes("---")) {
    fileContent.push("---")
    fileContent.push('date: ' + date.toISOString())
    fileContent.push('title: ' + title)
    fileContent.push('category: note')
    fileContent.push('---')
  }
  fileContent.push(content)

  /* construct the fauna query */
  return octokit.repos.createOrUpdateFileContents({
    owner: "matsimitsu",
    repo: "matsimitsu.com",
    message: ("Adding note: " + title),
    path: "source/notes/" + filename + ".html.md",
    content: Buffer.from(fileContent.join("\n")).toString("base64")
  }).then((response) => {
    callback(null, {
      statusCode: 201,
      headers: {
        Location: "https://matsimitsu.com/notes",
      }
    });
  }).catch((error) => {
    console.log("error", error)
    /* Error! return the error with statusCode 400 */
    return callback(null, {
      statusCode: 400,
      body: JSON.stringify(error)
    })
  })
}
