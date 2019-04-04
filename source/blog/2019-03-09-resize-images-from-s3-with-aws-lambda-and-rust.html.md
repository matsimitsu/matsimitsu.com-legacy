---
title: "Resize images from s3 with AWS Lambda and Rust"
date: 2019-03-09 10:00:00 UTC
tags:
summary: My site contains a lot of images and resizing them for different devices (mobile phone, tabled, desktop etc.) takes a lot of time and (upload) bandwidth. This is especially annoying on Hotel Wi-Fi in a far-away country. With the help of AWS Lambda and Rust I made this into a smooth process.
---

The very first iteration of my site didn’t have resized images and always showed the full 2200 pixels wide images, this was great on my local (desktop) machine, but when I tried visiting the site in a hotel in Cambodia, the site took ages to load.

Resizing the images locally worked fine, but took a lot of time and uploading an image in five different sizes on slow Wi-Fi took ages, if it worked at all.

I then switched to using an image resize proxy that took images from disk and re-sized them on the fly, caching the result in Nginx. This worked okay, but there was a tradeoff between server specs and monthly cost. Low specs meant that on an uncached page it took minutes before all images were resized, while high specs meant high monthly cost for a server that was idle 99% of the time.

The solution to not running a server was switching to [imgix](https://imgix.com), it’s a great service that resizes images for you and does so with good quality and speed, but there’s a minimum fee of $10,00 a month, wether you use the service or not, and the costs go up pretty quickly as you add more and more photos. This is in addition to the S3 storage costs that imgix uses as the source for its proxy.

This lead me to the latest solution, use S3 to store the images (imgix also requires s3 as a source, so the images were already there) and AWS Lambda to resize the images on upload.

This means I only have to upload an image once and Lambda will take care of all the resized variants. I found a few (Javascript) solutions, and [aws-lambda-image](https://github.com/ysugimoto/aws-lambda-image) looked the easiest to use. This ran for a few months, before I decided to roll my own solution for a few reasons.

aws-lambda-image does a lot of magic and uses [Claudia](https://claudiajs.com/) to manage the Lambda settings. While it works great, I don’t really like tools that require high-level access to AWS API’s and configure a lot for you automatically. I have no idea what’s happening after running the commands.

Another risk for me is that it Runs on Node, which eventually will require an upgrade at some point, which has a high risk of breaking the function and these things always happen at the most inconvenient times.

What I wanted is a single binary that just keeps working and requires no upkeep, configured by myself so I know what’s happening and ideally more efficient than the NodeJS solution. It’s also a great excuse to play with Rust some more and the just released [Rust AWS Lambda Runtime](https://github.com/awslabs/aws-lambda-rust-runtime).

## The goal

I wanted something similar to the Javascript solution used. It should listen to events emitted when a file is uploaded to S3 and resize the image in several widths (`360px`, `720px`, `1200px` and `2200px`).

Before we start, you can follow along with the complete source on [GitHub](https://github.com/matsimitsu/lambda-image-resize-rust/)

### A binary project

Lets start by making a new Rust project, it should be a binary project and we need to make a few tweaks to the Cargo TOML to make sure Lambda can run the binary.

```toml
[package]
name = "lambda-image-resize-rust"
version = "0.1.0"
authors = ["Robert Beekman <robert@matsimitsu.nl>"]

[dependencies]
lambda_runtime = "0.1"

[[bin]]
name = "bootstrap"
path = "src/main.rs"
```


The way AWS Lambda works is that it starts the app/binary for you and then you have to call a certain endpoint from the app to receive new jobs to process. The `lambda_runtime` crate abstracts this process away and all you have to do is implement an event handler that will be called with the `lambda!` call.

Cargo (heh) culting from the example app, we start a logger and run the lambda for the AWS Runtime.

```rust
fn main() -> Result<(), Box<Error>> {
    simple_logger::init_with_level(log::Level::Info)?;

    lambda!(handle_event);

    Ok(())
}
```

The `handle_event` function will be called with the JSON result from the endpoint the runtime has called for us. Let’s convert this into a nice struct with Serde, by using the [AWS-lambda-events crate](https://github.com/LegNeato/aws-lambda-events/blob/master/aws_lambda_events/src/generated/s3.rs).


### Handle S3 events

This event contains one or more “records” that represent the S3 uploads it has received.

```rust
fn handle_event(event: Value, ctx: lambda::Context) -> Result<(), HandlerError> {
    let config = Config::new();

    let s3_event: S3Event =
        serde_json::from_value(event).map_err(|e| ctx.new_error(e.to_string().as_str()))?;

    for record in s3_event.records {
        handle_record(&config, record);
    }
    Ok(())
}
```


For each upload we have to get the file from S3, convert the file to one or more image variations and upload those back to S3 again. There are a couple of crates that implement the S3 API, I went with [rust-s3](https://github.com/durch/rust-s3) as it looked simple and small.

AWS Lambda sets a couple of [default ENV vars](https://docs.aws.amazon.com/lambda/latest/dg/current-supported-versions.html), among those it sets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, the `rust-s3` crate can detect those with the `Credentials::default()` function.

In my case I want to store the images in the same bucket as the source, just in a different location, so I can use the information from the S3 event to determine the region and bucket.

```rust
fn handle_record(config: &Config, record: S3EventRecord) {
    let credentials = Credentials::default();
    let region: Region = record
        .aws_region
        .expect("Could not get region from record")
        .parse()
        .expect("Could not parse region from record");
    let bucket = Bucket::new(
        &record
            .s3
            .bucket
            .name
            .expect("Could not get bucket name from record"),
        region,
        credentials,
    );
    let source = record
        .s3
        .object
        .key
        .expect("Could not get key from object record");
}
```

### Recursion

Now that we have all the required configuration to get and store images on S3, we have to do a sanity check first. We listen to an S3 event for uploaded images, but this function also uploads images to S3, this means that if you make a mistake in the configuration, it could send out an S3 event for each file you put back into the bucket.

This can mean that you’ll process your own (resized) images again, and since we generate more than one variant for each uploaded image. Combined with the power of Lambda and it's concurrency, it can mean that you’ll quickly generate thousands of new Lambda tasks, forcing you to hit the dreaded “panic button” in the Lambda UI, before you rack up an enormous AWS bill. (This *may* or may not come from my own experience ;)).

After resizing the image, we’ll append `-<size>` to the filename (e.g. `foo.jpg` becomes `foo-360.jpg`). To prevent this Lambda recursion we check the uploaded filename to see if it was already resized.

```rust
    /* Make sure we don't process files twice */
    for size in &config.sizes {
        let to_match = format!("-{}.jpg", size);
        if source.ends_with(&to_match) {
            warn!(
                "Source: '{}' ends with: '{}'. Skipping.",
                &source,
                &to_match
            );
            return;
        }
    }
```

### Get images from- and upload to S3


Now that we know for sure we have the right image, let’s fetch it from S3 and load it from memory into the `image` crate.

```rust
    let (data, _) = bucket
        .get(&source)
        .expect(&format!("Could not get object: {}", &source));

    let img = image::load_from_memory(&data)
        .ok()
        .expect("Opening image failed");
```

### Resize the images

With the image in memory we can resize it. Depending on the memory you give a Lambda function, you can get one or more CPU cores to your disposal. To get the maximum from our billed execution time, I opted to use the great [rayon-rs](https://github.com/rayon-rs/rayon) crate to execute the resizes in parallel. All you have to do to process the image in parallel is to replace `iter()` with `.par_iter()`, awesome!


```rust
    let _: Vec<_> = config
        .sizes
        .par_iter()
        .map(|size| {
            let buffer = resize_image(&img, &size).expect("Could not resize image");

            let mut target = source.clone();
            for (rep_key, rep_val) in &config.replacements {
                target = target.replace(rep_key, rep_val);
            }
            target = target.replace(".jpg", &format!("-{}.jpg", size));
            let (_, code) = bucket
                .put(&target, &buffer, "image/jpeg")
                .expect(&format!("Could not upload object to :{}", &target));
            info!("Uploaded: {} with: {}", &target, &code);
        })
        .collect();
```

Another thing we do is loop through `&config.replacemens`, this is another feature to combat the recursion problem we have, by allowing us to replace certain parts of the (input) path of a file.

We can set a `REPLACEMENTS` env var with key/value strings, such as `"original:resized"`.

With an input path of `/original/trips/asia2018/img_01.jpg` this will be converted to `/resized/trips/asia2018/img_01.jpg`. Combined with the input filter on the AWS Lambda configure page you can make sure converted images are never processed twice.

Finally we need to implement the actual resize function called in the code above.

it takes the image and a new width, calculates the ratio and generates the new needed height. We then call the image crate function and use the `ImageOutputFormat::JPEG(90)` ENUM to set the JPEG quality to `90` (from the default `75`).

```rust
fn resize_image(img: &image::DynamicImage, new_w: &f32) -> Result<Vec<u8>, ImageError> {
    let mut result: Vec<u8> = Vec::new();

    let old_w = img.width() as f32;
    let old_h = img.height() as f32;
    let ratio = new_w / old_w;
    let new_h = (old_h * ratio).floor();

    let scaled = img.resize(*new_w as u32, new_h as u32, image::FilterType::Lanczos3);
    scaled.write_to(&mut result, ImageOutputFormat::JPEG(90))?;

    Ok(result)
}
```

You can find the complete project on [GitHub](https://github.com/matsimitsu/lambda-image-resize-rust).

### Compiling for AWS Lambda

With a working binary we now need to (cross)compile it for the right environment/distribution. Luckily a person named [softprops](https://hub.docker.com/u/softprops) created a [docker container](https://hub.docker.com/r/softprops/lambda-rust/) that has all the tools we need to compile this binary to be used with the Lambda image.

```bash
	docker run --rm \
		-v ${PWD}:/code \
		-v ${HOME}/.cargo/registry:/root/.cargo/registry \
		-v ${HOME}/.cargo/git:/root/.cargo/git \
		softprops/lambda-rust
```

This will generate a `bootstrap.zip` file in `target/lambda/release`. You can also get the `bootstrap.zip` from te [releases page](https://github.com/matsimitsu/lambda-image-resize-rust/releases).

### Configuring Lambda

With a freshly compiled binary, we're nearly there. We need to do two things, configure a IAM role that allows the Lambda function to write logs and has access to the S3 bucket and configure the Lambda function itself.

Let’s start with the IAM Role, we’ll have to add two policies, one that allows the function to log and one that allows access to S3, it should look something like:

![image](https://d3khpbv2gxh34v.cloudfront.net/r/blog/image-resize-rust/iam-role.jpg)

Bonus points if you lock the S3 role down a bit more, by not allowing it to remove items.

With a role configured, we can configure the lambda function, we have to set the `SIZES` and `REPLACEMENTS` ENV vars and I found that the function works best with at least `1024MB` of memory assigned.

![image](https://d3khpbv2gxh34v.cloudfront.net/r/blog/image-resize-rust/lambda-config-options.jpg)

Attach the generated `bootstrap.zip` file and save the function.

Finally we need to configure the S3 events, pick “S3” events from the “Add triggers” section on the page and pick the option that says “All upload events”. I’ve also set the prefix/suffix option to prevent our recursion problem.

![image](https://d3khpbv2gxh34v.cloudfront.net/r/blog/image-resize-rust/lambda-s3-config.jpg)

Save the function again and upload an image to test, if everything went well, it should generate resized images after the upload is complete. You can verify it works (or catch any errors) on AWS Cloudwatch, it should look something like this:

```
START RequestId: 7e7886d6-f983-4ef7-9916-83ab53874c6c Version: $LATEST
2019-03-09 15:07:35 INFO [lambda_runtime::runtime] Received new event with AWS request id: 7e7886d6-f983-4ef7-9916-83ab53874c6c
2019-03-09 15:07:35 INFO [bootstrap] Fetching: original-rust/blog/image-resize-rust/lambda-config.jpg, config: Config { sizes: [360.0, 720.0, 1200.0, 2200.0], replacements: [("original-rust", "r"), ("original", "r")] }
2019-03-09 15:07:36 INFO [bootstrap] Uploaded: r/blog/image-resize-rust/lambda-config-360.jpg with: 200
2019-03-09 15:07:36 INFO [bootstrap] Uploaded: r/blog/image-resize-rust/lambda-config-1200.jpg with: 200
2019-03-09 15:07:36 INFO [bootstrap] Uploaded: r/blog/image-resize-rust/lambda-config-720.jpg with: 200
2019-03-09 15:07:38 INFO [bootstrap] Uploaded: r/blog/image-resize-rust/lambda-config-2200.jpg with: 200
2019-03-09 15:07:38 INFO [lambda_runtime::runtime] Response for 7e7886d6-f983-4ef7-9916-83ab53874c6c accepted by Runtime API
END RequestId: 7e7886d6-f983-4ef7-9916-83ab53874c6c
REPORT RequestId: 7e7886d6-f983-4ef7-9916-83ab53874c6c	Init Duration: 86.53 ms	Duration: 2944.40 ms	Billed Duration: 3100 ms Memory Size: 1024 MB	Max Memory Used: 125 MB
```


## Future goals

You can find the source on [GitHub](https://github.com/matsimitsu/lambda-image-resize-rust) and a ready-to-go `bootstrap.zip` on the [relase page](https://github.com/matsimitsu/lambda-image-resize-rust/releases).

The binary works great and has resized many images already. With Amazon's generous free Lambda tier, resizing all the images on my blog has cost me a grand total of **$0.61**. There is room for improvement, however. Error handling can be a lot nicer than `.expect()` everywhere, though as long as it logs the error in CloudWatch it works for me right now.

It would be nice if it could handle more image formats, while the `image` crate works fine with input formats such as GIF, JPEG, PNG and WEBP, right now I only generate JPEG images. I like it to generate WEBP images along side the JPEGs but I couldn’t find any crate that can generate WEBP images. If you happen to know one or have other feedback on this post, please let me know [by email](mailto:hello@matsimitsu.nl) or [tweet me](https://twitter.com/matsimitsu).


### References / Resources

* https://aws.amazon.com/blogs/opensource/rust-runtime-for-aws-lambda/
* https://github.com/srijs/rust-aws-lambda
* https://dev.to/adnanrahic/a-crash-course-on-serverless-with-aws---image-resize-on-the-fly-with-lambda-and-s3-4foo
* https://github.com/awslabs/aws-lambda-rust-runtime/issues/29
* https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html
* https://hub.docker.com/r/softprops/lambda-rust/
