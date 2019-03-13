# SwiftApi

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `swift_api` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swift_api, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/swift_api](https://hexdocs.pm/swift_api).




```elixir
client = %SwiftApi.Client{user_name: username,
                          password: password,
                          domain_id: domain_id,
                          url: url,
                          project_id: project_id,
                          ca_certificate_path: ca_certificate_path,
                          container: container,
                          temp_url_key: temp_url_key}
container = "mytest"
filename = "test_data.html"
SwiftApi.Worker.container_create(client, container)
SwiftApi.Worker.object_create(client, "#{container}/#{filename}", "<html><body><p>Hello, test user!</p></body></html>")
SwiftApi.Worker.swift_get(client, "/#{container}/#{filename}")
SwiftApi.Worker.swift_object_temp_url(client, container, filename, 60*60)
```