defmodule Octopus.Configs do
  @services_namespace Application.compile_env(:octopus, :services_namespace) || "Octopus.Services"

  def services_namespace, do: @services_namespace
end
