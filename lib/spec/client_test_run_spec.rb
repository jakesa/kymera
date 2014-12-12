# require_relative '../../lib/kymera'
require 'kymera'
Kymera.run_tests('~/apollo/source/integration_tests/features/login_and_session/login.feature', 'cucumber', ['-p default'], 'develop', true)