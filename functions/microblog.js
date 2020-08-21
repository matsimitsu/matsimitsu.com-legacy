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
  return client.query(q.Paginate(q.Match(q.Index("posts"))).size(Value(10000)))
  .then((response) => {
    console.log("success", response);
    callback(null, response);
  }).catch((error) => {
    console.log("error", error)
    /* Error! return the error with statusCode 400 */
    return callback(null, {
      statusCode: 400,
      body: JSON.stringify(error)
    })
  })
}
