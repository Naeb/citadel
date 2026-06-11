# frozen_string_literal: true

Rails.application.routes.draw do
  get "health", to: proc { [200, {}, ["ok"]] }
end
