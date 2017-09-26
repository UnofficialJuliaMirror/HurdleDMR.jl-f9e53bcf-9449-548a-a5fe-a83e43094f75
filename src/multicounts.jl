################################################################################
# Squencial processing of multiple counts matrices
################################################################################

"""
Multiple Counts Distributed Multinomial Regression by running independent poisson gamma lasso regression to each column of counts,
picks the minimum AICc segement of each path, and returns a coefficient matrix (coefs) representing point estimates
for the entire multinomial (includes the intercept if one was included).
Unlike dmr(), mcdmr() takes a vector of counts matrices and sequencially
  1. regresses each counts matrix on the covars genrating an srproj Z (includes total counts m)
  2. accumulated srproj z into Z
  3. uses [covars Z] for subsequent regressions
Returns the accumulated Z matrix and a vector of coefficient matrices
"""
function mcdmr{T<:AbstractFloat}(covars::AbstractMatrix{T},multicounts::Vector,projdir::Int; intercept=true, kwargs...)
	L = length(multicounts)
  n,p = size(covars)
	info("fitting mcdmr to $L counts matrices")
  multicoefs = Array(Matrix{T},L,1)
  Z = Array(T,n,0)
	for l=1:L
		info("fitting dmr to counts matrix #$l on $p covars + $(size(Z,2)) previous SR projections ...")
		# get l'th counts matrix
		counts = multicounts[l]
		# fit dmr
		multicoefs[l] = dmr([covars Z],counts; intercept=intercept, kwargs...)
		# collapse counts into low dimensional SR projection
		z = srproj(multicoefs[l],counts,projdir; intercept=intercept)
		# append z to Z
	  Z = [Z z]
	end
  Z, multicoefs
end