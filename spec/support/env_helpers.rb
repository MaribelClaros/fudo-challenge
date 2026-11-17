# frozen_string_literal: true

# Temporarily sets environment variables for the duration of a block,
# restoring the original values afterwards. A nil value removes the variable.
module EnvHelpers
  def with_env(vars)
    original = vars.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    apply_env(vars)
    yield
  ensure
    apply_env(original) if original
  end

  private

  def apply_env(vars)
    vars.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end
