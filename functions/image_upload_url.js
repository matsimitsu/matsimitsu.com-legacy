const AWS = require('aws-sdk')
const { TOKEN, MY_AWS_ACCESS_KEY_ID, MY_AWS_SECRET_ACCESS_KEY, MY_S3_BUCKET_NAME, MY_AWS_REGION } = process.env

const s3 = new AWS.S3({
  signatureVersion: 'v4',
  region: MY_AWS_REGION,
  credentials: new AWS.Credentials(MY_AWS_ACCESS_KEY_ID, MY_AWS_SECRET_ACCESS_KEY)
})

module.exports.handler = async (event, context) => {
  const body = JSON.parse(event.body)
  const { fileName, fileType, token } = body

  if (!token && token != TOKEN) {
    return {
      statusCode: 401,
      body: JSON.stringify({
        message: 'Missing or invalid token'
      }),
    }
  }

  if (!fileName && !fileType) {
    return {
      statusCode: 400,
      body: JSON.stringify({
        message: 'Missing fileName or fileType on body'
      }),
    }
  }

  const s3Params = {
    Bucket: MY_S3_BUCKET_NAME,
    Key: "/r/notes/" + fileName,
    ContentType: fileType,
    ACL: 'public-read'
  }

  const uploadURL = s3.getSignedUrl('putObject', s3Params)

  return {
    statusCode: 200,
    body: JSON.stringify({
      uploadURL: uploadURL
    }),
  }
}
