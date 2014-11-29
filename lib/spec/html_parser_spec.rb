
# require 'kymera'
require_relative '../../lib/kymera/cucumber/cucumber_html_parser'

results =  "Using the default profile...
[36m@smoke_prod[0m
Feature: Login

As a user
I want to login
So that I can do freight matching

# JS - no longer valid
#  Scenario: e. the footer is present on the login page
#    Given I am at the login page
#    Then I see the Terms and Conditions link
#    And I see the Privacy link
#    And I see the DAT copyright string
Scenario: f. the footer is present on the welcome page[90m       # c:\apollo\source\integration_tests\features\login_and_session\login.feature:39[0m
[32mGiven I am logged in[90m                                       # features/step_definitions/login/login_steps.rb:5[0m[0m
[32mThen I see the home page has the Terms and Conditions link[90m # features/step_definitions/login/login_steps.rb:109[0m[0m
[32mAnd I see the home page has the Privacy link[90m               # features/step_definitions/login/login_steps.rb:113[0m[0m
[32mAnd I see the home page has the DAT copyright string[90m       # features/step_definitions/login/login_steps.rb:117[0m[0m

1 scenario ([32m1 passed[0m)
4 steps ([32m4 passed[0m)
0m14.218s
Using the default profile...
[36m@smoke_prod[0m
Feature: Login

As a user
I want to login
So that I can do freight matching

Scenario: d. invalid username, valid password[90m            # c:\apollo\source\integration_tests\features\login_and_session\login.feature:28[0m
[32mGiven I login with invalid username and valid password[90m # features/step_definitions/login/login_steps.rb:14[0m[0m
[32mThen I see an invalid login message[90m                    # features/step_definitions/login/login_steps.rb:78[0m[0m

1 scenario ([32m1 passed[0m)
2 steps ([32m2 passed[0m)
0m22.000s
Using the default profile...
[36m@smoke_prod[0m
Feature: Login

As a user
I want to login
So that I can do freight matching

Scenario: c. valid username, invalid password[90m            # c:\apollo\source\integration_tests\features\login_and_session\login.feature:23[0m
[32mGiven I login with valid username and invalid password[90m # features/step_definitions/login/login_steps.rb:9[0m[0m
[32mThen I see an invalid login message[90m                    # features/step_definitions/login/login_steps.rb:78[0m[0m

1 scenario ([32m1 passed[0m)
2 steps ([32m2 passed[0m)
0m23.261s"


parsed_results = Kymera::Cucumber::HTMLResultsParser.to_html(results)
p parsed_results.length
parsed_results.each do |result|
  puts "#############################"
  puts result
  puts "#############################"
end