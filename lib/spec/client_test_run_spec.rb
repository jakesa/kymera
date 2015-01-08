require_relative '../../lib/kymera'
# require 'kymera'
Kymera.run_tests('c:/apollo/source/integration_tests/features/posting/entry_common', 'cucumber', ['-p default'], 'develop', true)
# Kymera.run_tests('c:/apollo/source/integration_tests/features/login_and_session/login.feature', 'cucumber', ['-p default'], 'develop', true)