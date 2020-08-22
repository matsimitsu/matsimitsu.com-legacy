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
  console.log("Function `microblog-create` invoked", data)
  console.log("Content: ", data["properties"]["content"])
  const title = data["properties"]["name"][0]
  const date = new Date()
  const filename = [date.toISOString().split('T')[0], title.replace(/[\W]+/g,"-")].join("-")
  const fileContent =
   ['---',
    'date: ' + date.toISOString(),
    'title: ' + title,
    'category: note',
    '---',
    data["properties"]["content"][0]["html"]
   ].join('\n');

  /* construct the fauna query */
  return octokit.repos.createOrUpdateFileContents({
    owner: "matsimitsu",
    repo: "matsimitsu.com",
    message: ("Adding note: " + title),
    path: "source/notes/" + filename + ".html.erb",
    content: Buffer.from(fileContent).toString("base64")
  }).then((response) => {
    console.log("success", response);
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
