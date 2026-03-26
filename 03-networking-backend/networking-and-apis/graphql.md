# GraphQL in Swift

## Overview

GraphQL is a query language for APIs that provides clients with precise control over requested data. Unlike REST, GraphQL allows fetching exactly what you need in a single request, reducing over-fetching and under-fetching problems.

## Main Topics

- [GraphQL Concepts](#graphql-concepts)
- [Queries](#queries)
- [Mutations](#mutations)
- [Subscriptions](#subscriptions)
- [Implementation](#implementation)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [GraphQL Official](https://graphql.org/)
- [Apollo iOS Client](https://www.apollographql.com/docs/ios/)

---

## GraphQL Concepts

### Query vs REST

```swift
// REST - Multiple endpoints, fixed data
GET /users/123
GET /users/123/posts
GET /users/123/friends

// GraphQL - Single endpoint, you define structure
POST /graphql
{
  query {
    user(id: 123) {
      name
      posts { title }
      friends { name }
    }
  }
}
```

### Key Benefits

```swift
// 1. Client-Driven Design
// Get exactly what you need

// 2. Single Request
// Multiple resources in one call

// 3. Strongly Typed
// Server schema enforces types

// 4. Nested Queries
// Natural relational queries

// 5. Real-time Updates
// Subscriptions for live data
```

---

## Queries

### Simple Query

```swift
// GraphQL Query definition
let queryString = """
{
  user(id: 123) {
    id
    name
    email
  }
}
"""

// Decoded response
struct User: Codable {
    let id: String
    let name: String
    let email: String
}

struct QueryResponse: Codable {
    let data: UserData
}

struct UserData: Codable {
    let user: User
}

// Send query
func fetchUser(id: Int) async throws -> User {
    let endpoint = "https://graphql.example.com/graphql"
    let query = """
    {
      user(id: \(id)) {
        id
        name
        email
      }
    }
    """
    
    let body = ["query": query]
    var request = URLRequest(url: URL(string: endpoint)!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(QueryResponse.self, from: data)
    return response.data.user
}
```

### Query Variables

```swift
// GraphQL with variables
let queryString = """
query GetUser($id: ID!, $includeEmail: Boolean!) {
  user(id: $id) {
    id
    name
    email @include(if: $includeEmail)
  }
}
"""

// Variables
let variables = [
    "id": "123",
    "includeEmail": true
]

// Request body
let body: [String: Any] = [
    "query": queryString,
    "variables": variables
]
```

### Nested Queries

```swift
// Complex nested query
let queryString = """
query {
  user(id: 123) {
    id
    name
    posts(limit: 10) {
      id
      title
      comments(limit: 5) {
        text
        author {
          name
        }
      }
    }
    friends {
      id
      name
    }
  }
}
"""

// Nested models
struct User: Codable {
    let id: String
    let name: String
    let posts: [Post]
    let friends: [User]
}

struct Post: Codable {
    let id: String
    let title: String
    let comments: [Comment]
}

struct Comment: Codable {
    let text: String
    let author: User
}
```

### Fragments

```swift
// Reusable query fragments
let queryString = """
fragment UserFields on User {
  id
  name
  email
  createdAt
}

query {
  user(id: 123) {
    ...UserFields
  }
  
  allUsers {
    ...UserFields
  }
}
"""
```

---

## Mutations

### Basic Mutation

```swift
// GraphQL Mutation
let mutationString = """
mutation CreateUser($name: String!, $email: String!) {
  createUser(input: {name: $name, email: $email}) {
    id
    name
    email
  }
}
"""

// Variables
let variables = [
    "name": "John Doe",
    "email": "john@example.com"
]

// Send mutation
func createUser(name: String, email: String) async throws -> User {
    let query = """
    mutation {
      createUser(input: {name: "\(name)", email: "\(email)"}) {
        id
        name
        email
      }
    }
    """
    
    let body = ["query": query]
    var request = URLRequest(url: URL(string: "https://graphql.example.com/graphql")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(QueryResponse.self, from: data)
    return response.data.user
}
```

### Update Mutation

```swift
// Update mutation
let queryString = """
mutation UpdateUser($id: ID!, $name: String!) {
  updateUser(id: $id, input: {name: $name}) {
    id
    name
    updatedAt
  }
}
"""

// Multiple operations
let queryString = """
mutation {
  createUser(input: {name: "Alice"}) {
    id
  }
  
  updateUser(id: 1, input: {name: "Bob"}) {
    id
  }
  
  deleteUser(id: 2)
}
"""
```

---

## Subscriptions

### Real-time Updates

```swift
// WebSocket subscription
let subscriptionString = """
subscription OnUserCreated {
  userCreated {
    id
    name
    email
  }
}
"""

// Using Apollo iOS
import Apollo

class UserSubscriber {
    let apolloClient: ApolloClient
    
    func subscribeToNewUsers() {
        let subscription = OnUserCreatedSubscription()
        
        apolloClient.subscribe(subscription: subscription) { result in
            switch result {
            case .success(let graphQLResult):
                if let user = graphQLResult.data?.userCreated {
                    print("New user: \(user.name)")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}
```

---

## Implementation

### Apollo iOS Client

```swift
import Apollo

// Configure Apollo Client
let apolloClient = ApolloClient(url: URL(string: "https://graphql.example.com/graphql")!)

// Query
let query = GetUserQuery(id: "123")

apolloClient.fetch(query: query) { result in
    switch result {
    case .success(let graphQLResult):
        if let user = graphQLResult.data?.user {
            print("User: \(user.name)")
        }
        
        if let errors = graphQLResult.errors {
            print("GraphQL Errors: \(errors)")
        }
        
    case .failure(let error):
        print("Network error: \(error)")
    }
}
```

### Custom GraphQL Client

```swift
// Simple custom GraphQL client
class GraphQLClient {
    let endpoint: URL
    
    init(endpoint: URL) {
        self.endpoint = endpoint
    }
    
    func query<T: Decodable>(_ query: String, variables: [String: Any]? = nil) async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["query": query]
        if let variables = variables {
            body["variables"] = variables
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        struct Response<T: Decodable>: Decodable {
            let data: T
            let errors: [GraphQLError]?
        }
        
        let response = try JSONDecoder().decode(Response<T>.self, from: data)
        
        if let errors = response.errors {
            throw GraphQLError.serverErrors(errors)
        }
        
        return response.data
    }
}

enum GraphQLError: Error {
    case serverErrors([GraphQLError])
}

struct GraphQLError: Decodable {
    let message: String
}

// Usage
let client = GraphQLClient(endpoint: URL(string: "https://graphql.example.com/graphql")!)

let query = """
{
  user(id: 123) {
    id
    name
    email
  }
}
"""

struct UserData: Decodable {
    let user: User
}

let result: UserData = try await client.query(query)
print(result.user.name)
```

---

## 🎯 Best Practices

### 1. Request Only What You Need
```graphql
# ✅ Efficient
query {
  user(id: 123) {
    id
    name
  }
}

# ❌ Over-fetching
query {
  user(id: 123) {
    id
    name
    email
    phone
    address
    preferences
    metadata
  }
}
```

### 2. Use Variables for Parameters
```graphql
# ✅ Reusable with variables
query GetUser($id: ID!) {
  user(id: $id) {
    name
  }
}

# ❌ Hard-coded values
query {
  user(id: "123") {
    name
  }
}
```

### 3. Use Fragments for Reuse
```graphql
# ✅ DRY with fragments
fragment UserFields on User {
  id
  name
  email
}

query {
  user1: user(id: 1) {
    ...UserFields
  }
  user2: user(id: 2) {
    ...UserFields
  }
}
```

---

## ❌ Common Mistakes

### Mistake 1: Over-fetching

**WRONG:**
```graphql
# ❌ Requesting too much data
query {
  user {
    id
    name
    email
    address
    phone
    preferences
    metadata
  }
}
```

**CORRECT:**
```graphql
# ✅ Only what's needed
query {
  user {
    id
    name
    email
  }
}
```

---

### Mistake 2: N+1 Queries

**WRONG:**
```graphql
# ❌ Inefficient - multiple requests
query {
  users {
    id
    name
    posts {
      title
    }
  }
}
```

**CORRECT:**
```graphql
# ✅ Single request with nesting
query {
  users {
    id
    name
    posts {
      title
    }
  }
}
```

---

## Related Topics

- [REST API](rest-api.md)
- [URLSession](urlsession.md)
- [Networking Best Practices](networking-and-apis.md)

---

**GraphQL enables efficient, flexible API interactions!**
