defmodule Octopus.Configs do
  @services_namespace "Octopus.Services"
  @sandbox_namespace "Octopus.Sandbox"

  def services_namespace, do: @services_namespace
  def sandbox_namespace, do: @sandbox_namespace
end
