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
client = %SwiftApi.Client{user_name: "os-rgsb-prod-rgsb-export",
                          password: "4ef19c227bd963ae0f8",
                          domain_id: "af578a7d3daa49fe922100ff11581fc8",
                          url: "https://auth.os.dc-cr.b-pl.pro",
                          project_id: "rgsb-prod",
                          ca_certificate_path: "/mili/ca.crt",
                          container: "documents"}
container = "mytest"
filename = "test_data.html"
SwiftApi.Worker.container_create(client, container)
SwiftApi.Worker.object_create(client, "#{container}/#{filename}", "<html><body><p>Hello, test user!</p></body></html>")
SwiftApi.Worker.swift_get(client, "/#{container}/#{filename}")
SwiftApi.Worker.swift_object_temp_url(client, container, filename, 60*60)
```
