/* code from functions/todos-create.js */
const faunadb = require('faunadb'); /* Import faunaDB sdk */

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

  /* configure faunaDB Client with our secret */
  const q = faunadb.query
  const client = new faunadb.Client({
    secret: process.env.FAUNADB_SECRET
  })

  /* parse the string body into a useable JS object */
  const data = JSON.parse(event.body)
  console.log("Function `microblog-create` invoked", data)
  const post = {
    data: {
      title: data["properties"]["name"][0],
      content: data["properties"]["content"][0],
      created_at: new Date().toISOString(),
      category: "post"
    }
  }
  /* construct the fauna query */
  return client.query(
    q.Create(q.Collection('microblog'),post))
  .then((response) => {
    console.log("success", response)
    /* Success! return the response with statusCode 200 */
    return callback(null, {
      statusCode: 200,
      body: JSON.stringify(response)
    })
  }).catch((error) => {
    console.log("error", error)
    /* Error! return the error with statusCode 400 */
    return callback(null, {
      statusCode: 400,
      body: JSON.stringify(error)
    })
  })
}
