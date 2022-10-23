defmodule Octopus.Definition.Storage do
  use GenServer

  defstruct definitions: Map.new()

  def start_link([]) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def init(%__MODULE__{} = state) do
    {:ok, state}
  end

  def add(definition) when is_map(definition) do
    GenServer.call(__MODULE__, {:add, definition})
  end

  def get(name) when is_binary(name) do
    GenServer.call(__MODULE__, {:get, name})
  end

  def handle_call({:add, definition}, _from, state) do
    name = definition[:name]
    state = %{state | definitions: Map.put(state.definitions, name, definition)}
    {:reply, definition, state}
  end

  def handle_call({:get, name}, _from, state) do
    definition = Map.get(state.definitions, name)
    {:reply, definition, state}
  end
end
