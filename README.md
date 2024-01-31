# Device Readings

The Device Readings API allows us to record counts at arbitrary intervals from different devices and exposes endpoints to gather this information.

## Getting Started

### Setup

#### API Credentials Setup

This API uses HTTP Basic Authentication, and we will need to update the credentials locally.

The `config/env_variables.rb.template` file is a template file that you can modify. Create a copy of it in the same directory, remove the `.template` at the end of the filename, and input your own credentials.

Example:
```
## config/env_variables.rb

ENV['API_USER'] = 'YOUR_USERNAME'
ENV['API_PASS'] = 'YOUR_PASSWORD'
```

#### Installation

1) Install [ruby](https://www.ruby-lang.org/en/documentation/installation/) version 3.2.2

Check Ruby version with:
```
ruby -v
```

You ay need to use [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io) to change to Ruby versions 3.2.2.

2) Install gems:
```
bundle install
```


### Usage

#### Starting the Server

Start the API server with:
```
rails s
```

#### Using the API

The following endpoints are exposed to interact with the API:

```
## POST /readings
Creates a new reading record.

Request Body Example:

{
  "readings": {
    "id": "36d5658a-6908-479e-887e-a949ec199272",
    "readings": [
      {
        "timestamp": "2021-09-29T16:08:15+01:00",
        "count": 2
      },
      {
        "timestamp": "2021-09-29T16:09:15+01:00",
        "count": 15
      }
    ]
  }
}

## GET /devices/:id/latest_timestamp
Returns the latest timestamp associated with a device.

## GET /devices/:id/cumulative_count
Returns the cumulative count associated with a device.
```

Once the API server is up and running, you'll be able to call these endpoints.

Using the values for API_USER and API_PASS that you set up previously, you could call the endpoints through curl (only do this with the dummy application, real credentials shouldn't be used like this).

```
## POST /readings
curl -u 'your_api_user:your_api_pass' http://localhost:3000/readings -H 'Content-Type: application/json' -d '{"readings":{"id":"36d5658a-6908-479e-887e-a949ec199272","readings":[{"timestamp":"2021-01-29T16:08:15+01:00","count":2}]}}'

## GET /devices/:id/latest_timestamp
curl -u 'your_api_user:your_api_pass' http://localhost:3000/devices/:id/latest_timestamp

## GET /devices/:id/cumulative_count
curl -u 'your_api_user:your_api_pass' http://localhost:3000/devices/:id/cumulative_count
```

## Design Strategy and Future Optimizations

### Data Storage

#### Where the Data is Stored

I decided to use MemoryStore, a cache built into Rails, to store my data in memory for two main reasons:
- it is thread safe
- we can set size limits (assuming that we are intending to work with smaller amounts of memory)

I explored a couple different options (e.g. using a global variable, sessions, etc.) but MemoryStore seemed to get us most of the way there without adding increased complexity, violation of design principles, and complicated testing.

There are potentially more involved solutions that could be worth exploring:
- sqlite in memory: I saw articles of some people tinkering with this. It would give us full flexibility over our models and associations, and help with concurrency issues.
- redis: redis stores its data in memory and can help us significantly with atomic operations, since it has its own version of transaction blocks (although rolling back could be more complicated)

#### How the Data is Stored

MemoryStore holds our device readings data in the following format:
```
key: device_id
value: {
  timestamps: [
    { timestamp: ..., count: ... }
    { timestamp: ..., count: ... }
  ],
  latest_timestamp: ...,
  cumulative_count: ...
}
```

This format allows us to:
- check for duplicate timestamps in O(1) time
- check for latest_timestamp in O(1) time
- check cumulative_count in O(1) time
- add timestamps in O(1) time

There is a big tradeoff for speed here. This structure can lead to problems once we start dealing with cache eviction (our data becomes too large). We would need to run calculations again to figure out the latest timestamp and cumulative count.

If we wanted this service to run forever with minimal intervention, different data structures need to be used to help with the cleanup process. I considered this out of scope for this assignment, although I'm happy to discuss this further.


#### Concurrency

If we had a database, we can use mechanisms like transaction blocks, pessimistic locking, etc. to ease worries over concurrency.

Since we are using shared data in memory, I wanted to use something to help concurrency issues like race conditions. The Reading model has an associated mutex, shared across all instances of this class. Again, this is a demonstration for concern, but something more robust should be considered in the future.

### Models

Because we don't have a database, we can't use models as extensively. I've decided to still incorporate them to:
- run validations on the data
- centralize how we interact with the stored data

This still gives the feel of a normal Rails application and allows us to further incorporate Rails convention.

### Controllers

#### Authentication

I included HTTP Basic Authentication with this API to show how authentication could look, and to demonstrate returning different errors (e.g. 401).

In a production application, we would want a more robust setup. Authentication could be handle by more robust gems like devise. There is also the issue of authorization, of who can perform specific actions, which can be handled by gems like pundit. I again considered this out of scope for the assignment.

#### Controller Design

I tried to keep the controllers thin and move reusable logic elsewhere (e.g. in a service, in the model, etc.)


## Thank You

Thank you for considering me as a candidate, and for taking the time to review this project!
