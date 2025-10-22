# DynamicForm

A library for creating dynamic forms with full backend validation using
changesets and calls to backend functions in Elixir Phoenix. Also supports
building forms through a WYSIWYG interface.

This library enables users to build forms dynamically through a visual interface,
then render those forms using standard Phoenix LiveView patterns with robust
validation and backend integration.

## Installation

When using as a path dependency in your Phoenix app:

```elixir
def deps do
  [
    {:dynamic_form, path: "../"}
  ]
end
```
