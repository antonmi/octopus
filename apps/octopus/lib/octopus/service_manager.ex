defmodule Octopus.ServiceManager do
  @moduledoc false

  use GenServer

  defstruct services: MapSet.new(),
            pid: nil

  def start_link([]) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def init(%__MODULE__{} = state) do
    state = %{state | pid: self()}

    {:ok, state}
  end

  @spec add(atom()) :: atom()
  def add(service) when is_atom(service) do
    GenServer.call(__MODULE__, {:add, service})
  end

  @spec remove(atom()) :: atom()
  def remove(service) when is_atom(service) do
    GenServer.call(__MODULE__, {:remove, service})
  end

  @spec services() :: MapSet.t()
  def services, do: GenServer.call(__MODULE__, :services)

  def handle_call({:add, service}, _from, state) do
    state = %{state | services: MapSet.put(state.services, service)}
    {:reply, service, state}
  end

  def handle_call({:remove, service}, _from, state) do
    state = %{state | services: MapSet.delete(state.services, service)}
    {:reply, service, state}
  end

  def handle_call(:services, _from, state) do
    {:reply, state.services, state}
  end
end
