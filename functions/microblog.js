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
  /* construct the fauna query */
  return client.query(q.Map(
    q.Paginate(q.Documents(q.Collection("microblog")), { size: 10000 }),
    q.Lambda(x => q.Get(x))
  )).then((response) => {
    console.log(response.data)
    callback(null, {
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(response.data.map(d => d.data)) });
  }).catch((error) => {
    console.log("error", error)
    /* Error! return the error with statusCode 400 */
    return callback(null, {
      statusCode: 400,
      body: JSON.stringify(error)
    })
  })
}
