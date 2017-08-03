###################################################################
# Positive Poisson GLM
###################################################################

# # Pkg.add("LambertW")
# Pkg.clone("https://github.com/robertdj/LambertW.jl.git")
using LambertW

###################################################################
# Distributions.jl extensions
###################################################################
doc"""
    PositivePoisson(λ)

A *PositivePoisson distribution* (aka zero-truncated Poisson, ZTP) descibes the number of
independent events occurring within a unit time interval, given the average rate of occurrence `λ`
and, importantly, given that the number is not zero.

$P(X = k) = \frac{\lambda^k}{k!(1-e^{-\lambda})} e^{-\lambda}, \quad \text{ for } k = 1,2,\ldots.$

```julia
PositivePoisson()        # PositivePoisson distribution with rate parameter 1
PositivePoisson(lambda)       # PositivePoisson distribution with rate parameter lambda

params(d)        # Get the parameters, i.e. (λ,)
mean(d)          # Get the mean arrival rate, i.e. λ
```

External links:

* [PositivePoisson distribution on Wikipedia](https://en.wikipedia.org/wiki/Zero-truncated_Poisson_distribution)

"""
immutable PositivePoisson <: DiscreteUnivariateDistribution
    λ::Float64

    PositivePoisson(λ::Real) = new(λ)
    PositivePoisson() = new(1.0)
end

import Base.minimum, Base.maximum
Distributions.@distr_support PositivePoisson 1 (d.λ == 0.0 ? 0 : Inf)

### Parameters
Distributions.params(d::PositivePoisson) = (d.λ,)
Distributions.rate(d::PositivePoisson) = d.λ
### Statistics
Distributions.mean(d::PositivePoisson) = d.λ / (1.0-exp(-d.λ))

function logfactorialapprox(n::Int)
  x=n+1.0::Float64
  (x-0.5)*log(x) - x + 0.5*log(2π) + 1.0/(12.0*x)
end

function logfactorial(n::Int)
  if n<2
    return 0.0
  end
  x=0.0::Float64
  for i=2:n
    x+=log(i)
  end
  x
end

# Note that the factorial will blow up with moderately large x
Distributions.pdf(d::PositivePoisson, x::Int) = d.λ^x / ((exp(d.λ)-1.0) * factorial(x))

# calculating the log factorial is too expensive, we use an approximation
# given here: http://www.johndcook.com/blog/2010/08/16/how-to-compute-log-factorial/
Distributions.logpdf(d::PositivePoisson, x::Int) = x*log(d.λ) - log(exp(d.λ)-1.0) - logfactorialapprox(x)

# for comparison we define the exact logpdf for the positive poisson
logpdf_exact(d::PositivePoisson, x::Int) = x*log(d.λ) - log(exp(d.λ)-1.0) - logfactorial(x)

# similar calculation for the regular poisson
logpdf_approx(d::Poisson, x::Int) = x*log(d.λ) - d.λ - logfactorialapprox(x)

###################################################################
# GLM.jl extensions
###################################################################
type LogProductLogLink <: Link end

# denoting by λ=e^η the intensity of the untruncated poisson
LAMBERTW_USE_NAN=true
λfn(μ) = μ + lambertw(-exp(-μ)*μ)

GLM.linkfun(::LogProductLogLink, μ) = log(λfn(μ))

function GLM.linkinv(::LogProductLogLink, η)
  λ = exp(η)
  λ / (1.0 - exp(-λ))
end

function GLM.mueta(::LogProductLogLink, η)
  λ = exp(η)
  expmλ = exp(-λ)
  μ = λ / (1.0 - expmλ)
  μ * (1.0 - μ*expmλ)
end

GLM.canonicallink(::PositivePoisson) = LogProductLogLink()
GLM.glmvar(::PositivePoisson, ::LogProductLogLink, μ, η) = μ * (1.0 - μ*exp(-exp(η)))
GLM.mustart(::PositivePoisson, y, wt) = y + oftype(y, 0.1)

function GLM.devresid(::PositivePoisson, y, μ)
  if y>1
    if μ>1
      λμ = λfn(μ)
      λy = λfn(y)
      2 * (y*(log(λy)-log(λμ)) - log(exp(λy)-1.0) + log(exp(λμ)-1.0))
    else
      typemax(μ) # +∞
    end
  else
    if μ>1
      -2 * log(-lambertw(-exp(-μ)*μ))
    else
      zero(μ)
    end
  end
end

GLM.dispersion_parameter(::PositivePoisson) = false

function GLM.loglik_obs(::PositivePoisson, y, μ, wt, ϕ)
  wt*logpdf(PositivePoisson(λfn(μ)), y)
end

# function GLM.dispersion(m::GLM.AbstractGLM, sqr::Bool=false)
#     wrkwts = m.rr.wrkwts
#     wrkresid = m.rr.wrkresid
#
#     if isa(m.rr.d, @compat Union{Binomial, Poisson, PositivePoisson})
#         return one(eltype(wrkwts))
#     end
#
#     s = zero(eltype(wrkwts))
#     @inbounds @simd for i = eachindex(wrkwts,wrkresid)
#         s += wrkwts[i]*abs2(wrkresid[i])
#     end
#     s /= df_residual(m)
#     sqr ? s : sqrt(s)
# end