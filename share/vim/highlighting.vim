:syn match perlFunction +\<\%(capture_tests\|results\|diags\|failures\|push_\(results\|diag\|failures\)\)\>\_s*+
:syn match perlFunction +\<\%(test_set\|test_cases\)\>\_s*+ nextgroup=perlMethodName
