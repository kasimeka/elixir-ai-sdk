ExUnit.start()

# Define mocks for Tesla
Mox.defmock(Tesla.MockAdapter, for: Tesla.Adapter)
Application.put_env(:tesla, :adapter, Tesla.MockAdapter)
