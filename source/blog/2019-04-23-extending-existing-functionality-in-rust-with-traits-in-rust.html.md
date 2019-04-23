---
title: Extending Protobuf with Traits in Rust
date: 2019-04-18 10:00:00 UTC
summary: Extend default behavior of code with Traits and default implementations. In this case we add new functionality to generated Protobuf code.
---

At AppSignal we use Protobuf to pass messages through Kafka. We picked this because we were already using Protobuf in our Agent and it works great for our use-case.

One of the benefits of Protobuf is that it generates Rust code based on the protocol definition, which we can extend through traits to add additional features.

A common thing we have to do in our processing pipeline is to merge two messages into one, e.g. merge two (count) metrics.

In this case we want to merge two `Counter` messages that look like this:

```protobuf
message Counter {
  int64 count = 1;
}
```

We can generate a Rust implementation of this protocol with `protoc` and extend this protocol using a trait.

> A **trait** can be used to define functionality a type must provide. You can also implement default methods for a trait that can be overridden.

In this case we implement a default function for our `CounterExt` trait.


```rust
extern crate protobuf;

pub mod protocol;

use protocol::Counter;

pub trait CounterExt {
    fn merge(&mut self, to_merge: &Counter)
}
```

In the code above we use the `protobuf` crate and define the generated Rust code with `protoc` as a public module. We also use the `Counter` message we defined in the protocol. Then we define a new trait for the counter, called CounterExt.

This code defines a new function for CounterExt, called `merge` that accepts another counter to merge.

Next up we need to create a default implementation for this function.

```rust

impl CounterExt for Counter {
    fn merge(&mut self, to_merge: &Counter) {
        let our_count = self.get_count();
        self.set_count(our_count + to_merge.get_count());
    }
}

```

In this method we take the given counter and add it’s value to `self`.

Now that we have created this trait with a default implementation we can use it to merge two counters directly on the Protobuf generated code.

This means we can operate directly on deserialised Protobuf messages without having to convert them to structs or create a new message to contain the computed value.

```rust
use rdkafka::message::ProtobufMessage;

// Use the protocol Counter and the trait.
use protocol::protocol::Counter;
use protocol::CounterExt;

fn process_message(key: String, message: ProtobufMessage) {
    match cache.get_mut().entry(key) {
        // We have an entry, merge the counter
        Entry::Occupied(mut cache_entry) => {
            cache_entry.get_mut().merge(&message);
        },
        // No entry, insert it
        Entry::Vacant(cache_entry) => {
            cache_entry.insert(message);
        }
    }
}
```

The code above gets called for each Kafka message and updates a local cache with the merged value of the received message if it exists.

And it inserts the message into the cache if it doesn't already exist.

By extending our Protobuf messages with default traits we save ourselvs a lot of hassle in the message processing function.

Besides merging we implement a few other methods on our Protobuf messages that handle merging and computation of quantiles/percentiles/mean values.

Like this article or have any comments? Contact me on [twitter](https://twitter.com/matsimitsu) or by [hello@matsimitsu.com](mailto:hello@matsimitsu.com)
