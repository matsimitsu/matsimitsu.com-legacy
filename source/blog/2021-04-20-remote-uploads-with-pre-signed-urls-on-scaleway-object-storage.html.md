---
title: Remote uploads with pre-signed URLs on Scaleway's object storage.
date: 2021-04-20 01:00:00 UTC
summary: "Or, make sure your headers match, otherwise you'll get a lot of strange errors."
---

A while ago Scaleway [announced their S3-compatible Object Storage](https://blog.scaleway.com/object-storage-general-availability/). It implements most, but not all of the S3 API.

In an attempt to de-Amazon my personal stack I tried to migrate my S3 storage to Object Storage, including a little app that lets me upload photos and videos for my blog, which then get resized and transcoded in the required formats.

This endeavour took me a while, because I kept getting Signature errors or other vague responses from the Scaleway endpoints. The tl;dr at the bottom shows the "correct" way to implement this pre-signed URL upload in both the back-end and the front-end.

## Pre-sign urls

In order to have direct uploads, where the file gets uploaded directly to Scaleway, instead of to my server which then has to upload it, we need a pre-signed url that my front-end can upload the file to.

I use [SvelteKit](http://kit.svelte.dev) for my backend, but it should work with any framework.

The nice thing about being S3 compatible is that we can use the official [aws-sdk](https://aws.amazon.com/sdk-for-javascript/).

The setup looks like this:

```node
import AWS from 'aws-sdk'

const scw = new AWS.S3({
  endpoint: "s3.nl-ams.scw.cloud",
  region: "nl-ams",
  accessKeyId: import.meta.env.VITE_SCALEWAY_ACCESS_KEY,
  secretAccessKey: import.meta.env.VITE_SCALEWAY_ACCESS_SECRET,
  signatureVersion: "v4",
  params: { Bucket: import.meta.env.VITE_SCALEWAY_BUCKET },
})

```

Make sure to set the `endpoint`, `region` and `signatureVersion` to the correct values. In my case the bucket is hosted in Amsterdam.

The `import.meta.env.VITE_<value>` statements are specific to SvelteKit, replace it with whatever your framework's way of accessing ENV vars is.

We can then expose a function that generates the pre-signed upload url.

```node
export async function uploadUrl(key, contentType) {
  return scw.getSignedUrl(
    'putObject',
    {
      Key: key,
      ACL: "public-read",
      ContentType: contentType
    }
  )
}
```

This function requires two parameters, the Key (or path) where the file will be stored and the ContentType. This so Scaleway can serve the content with the correct format. (e.g. `image/jpg`).

## CORS

Since we'll be posting directly to the upload url from our own web-app, we need to setup the correct CORS headers. Otherwise your browser will reject any POST requests to the pre-signed url.

My Scaleway lib exposes a `cors()` function that calls the Scaleway API and sets the correct headers. You only have to call this function once.

```node
export async function cors() {
  return await scw.putBucketCors({CORSConfiguration: {
    "CORSRules": [
      {
        "AllowedOrigins": ["*"],
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "HEAD", "POST", "PUT", "DELETE"],
      }
    ]
  }}).promise()
}
```

Note that these are not the most specific CORS headers, it's best to limit the allowed origins to the domain where your web-app is served.

## API

Now that the back-end code is mostly done we have to expose the library to our front-end through an endpoint.

With SvelteKit, it looks like below, but this code should be adapted to whatever your framework requires.

```node
import {
  isAuthenticated,
  INVALID_AUTH_RESPONSE,
  invalidRequest
} from '$lib/api/auth'
import { uploadUrl } from '$lib/api/scw'

export async function post(request) {
  if (!isAuthenticated(request)) {
    return INVALID_AUTH_RESPONSE
  }
  if (!request.body.path) {
    return invalidRequest({ path: "Path field is requried" })
  }
  const url = await uploadUrl(
    request.body.path,
    request.body.contentType
  )

  return {
    status: 200,
    body: { url: url }
  }
}
```

It could use a bit more error handling, but works for now :)

## The front-end

In our front-end we need to create a number of requests for each file we'd like to upload, we need to:

* Get a Pre-signed URL from the backend
* Upload the file to this URL

I put this code in a library to not pollute my other front-end code

```node
export async function remoteUpload(key, file) {
	const url = await getPresignedUrl(key, file)
	return await remoteUploadFile(url, file)
}

// Get pre-signed upload url from backend
async function getPresignedUrl(key, file) {
	const response = await fetch('/api/uploads/presign-url', {
		method: 'POST',
		body: JSON.stringify({
			path: key,
			contentType: file.type
		}),
		headers: {
			'Content-Type': 'application/json'
		}
	})
	const presignData = await response.json()
	return presignData.url
}

// Upload file to external S3-compatible endpoint
async function remoteUploadFile(url, file) {
	const response = await fetch(decodeURI(url), {
		method: 'PUT',
		body: file,
		headers: {
		  'x-amz-acl': 'public-read',
		  'Content-Type': file.type
	  }
	})

	return await response.text()
}
```

The key thing to mention here is to match the headers for the POST to Scaleway's Pre-Signed url. If you want to make it publicly available the `x-amz-acl` header needs to be included here, otherwise you'll either get Signature mismatch errors or other vague errors.

The final piece is to hook up the upload code to a form, in Svelte it looks something like this:

```svelte
<script>
	import remoteUpload from '$lib/helpers/remoteUpload'
	import Button from '$lib/components/Button.svelte'

	let fileinput
	const onFileSelected = async (e) => {
		for (const file of e.target.files) {
			await remoteUpload(`files/${file.name}`, file)
		}
	}
</script>
<div id="uploadForm">
	<div id="form">
		<Button
			value="Choose file(s)"
			on:click={() => fileinput.click()}
		/>
		<input
			style="display:none"
			type="file"
			accept=".jpg, .jpeg, .png, .mp4"
			multiple
			on:change={(e) => onFileSelected(e)}
			bind:this={fileinput}
		/>
	</div>
</div>
```

## TL;DR

In order to upload a publicly readable file to a pre-signed URL with Scaleway you need to make sure the **given headers for the pre-signed URL and your `fetch` request in the browser match.**

The backend call should look like:

```nodejs
import AWS from 'aws-sdk'

const scw = new AWS.S3({
  endpoint: "s3.nl-ams.scw.cloud",
  region: "nl-ams",
  accessKeyId: import.meta.env.VITE_SCALEWAY_ACCESS_KEY,
  secretAccessKey: import.meta.env.VITE_SCALEWAY_ACCESS_SECRET,
  signatureVersion: "v4",
  params: { Bucket: import.meta.env.VITE_SCALEWAY_BUCKET },
})

export async function uploadUrl(key, contentType) {
  return scw.getSignedUrl(
    'putObject',
    {
      Key: key,
      ACL: "public-read",
      ContentType: contentType
    }
  )
}
```

and the `fetch` request in the front-end like:

```nodejs
// Upload file to external S3-compatible endpoint
async function remoteUploadFile(url, file) {
	const response = await fetch(decodeURI(url), {
		method: 'PUT',
		body: file,
		headers: {
		  'x-amz-acl': 'public-read',
		  'Content-Type': file.type
	  }
	})

	return await response.text()
}
```
