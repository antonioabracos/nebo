#!/usr/bin/env python3
prior_mean, prior_precision = 0.0, 1.0
observation_sum, n = 6.0, 3
precision = prior_precision + n
mean = (prior_precision * prior_mean + observation_sum) / precision
variance = 1.0 / precision
assert (mean, precision, variance) == (1.5, 4.0, 0.25)
print("RF46_G37_F05_ORACLE_PASS family=mean_field_conjugate mean=1.5 precision=4 variance=0.25 status=analytic")
