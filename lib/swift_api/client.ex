defmodule SwiftApi.Client do
  @moduledoc false

  defstruct user_name: nil,
            password: nil,
            domain_id: nil,
            domain_name: nil,
            url: nil,
            project_id: nil,
            ca_certificate_path: nil,
            container: nil
end
